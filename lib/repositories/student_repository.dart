import 'package:drift/drift.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';
import 'package:tattoo/services/student_query/student_query_service.dart';
import 'package:tattoo/utils/fetch_with_ttl.dart';

/// Aggregated academic data for one semester.
///
/// Groups a [UserAcademicSummary] with its per-course [ScoreDetail] rows
/// and [UserSemesterRanking] entries.
typedef SemesterRecordData = ({
  UserAcademicSummary summary,
  List<ScoreDetail> scores,
  List<UserSemesterRanking> rankings,
});

/// Provides the [StudentRepository] instance.
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    database: ref.watch(databaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
    studentQueryService: ref.watch(studentQueryServiceProvider),
  );
});

/// Repository for student academic data.
class StudentRepository {
  final AppDatabase _database;
  final AuthRepository _authRepository;
  final StudentQueryService _studentQueryService;

  StudentRepository({
    required AppDatabase database,
    required AuthRepository authRepository,
    required StudentQueryService studentQueryService,
  }) : _database = database,
       _authRepository = authRepository,
       _studentQueryService = studentQueryService;

  /// Gets aggregated academic records grouped by semester.
  ///
  /// Returns cached data if fresh (within TTL). Set [refresh] to `true` to
  /// bypass TTL (pull-to-refresh).
  Future<List<SemesterRecordData>> getSemesterRecords({
    bool refresh = false,
  }) async {
    final user = await _database.select(_database.users).getSingleOrNull();
    if (user == null) throw NotLoggedInException();

    final cached = await _buildSemesterRecordData(user.id);

    return fetchWithTtl(
      cached: cached.isEmpty ? null : cached,
      getFetchedAt: (_) => user.scoreDataFetchedAt,
      fetchFromNetwork: () => _fetchSemesterRecordsFromNetwork(user.id),
      refresh: refresh,
    );
  }

  Future<List<SemesterRecordData>> _fetchSemesterRecordsFromNetwork(
    int userId,
  ) async {
    final (semesters, gpas, rankings) = await _authRepository.withAuth(
      () async {
        final semestersFuture = _studentQueryService.getAcademicPerformance();
        final gpasFuture = _studentQueryService.getGpa();
        final rankingsFuture = _studentQueryService.getGradeRanking();
        return (semestersFuture, gpasFuture, rankingsFuture).wait;
      },
      sso: [.studentQueryService],
    );

    final gpaBySemester = <String, double>{};
    for (final gpa in gpas) {
      if (gpa.semester case (year: final year?, term: final term?)) {
        gpaBySemester['$year-$term'] = gpa.grandTotalGpa;
      }
    }

    final rankingsBySemester = <String, List<GradeRankingEntryDto>>{};
    for (final ranking in rankings) {
      if (ranking.semester case (year: final year?, term: final term?)) {
        rankingsBySemester['$year-$term'] = ranking.entries;
      }
    }

    await _database.transaction(() async {
      final fetchedSemesterIds = <int>{};

      for (final semester in semesters) {
        if (semester.semester case (year: final year?, term: final term?)) {
          final semesterRow = await _database.getOrCreateSemester(year, term);
          final semesterId = semesterRow.id;
          fetchedSemesterIds.add(semesterId);
          final key = '$year-$term';

          final summaryId =
              (await _database
                      .into(_database.userSemesterSummaries)
                      .insertReturning(
                        UserSemesterSummariesCompanion.insert(
                          user: userId,
                          semester: semesterId,
                          average: Value(semester.average),
                          conduct: Value(semester.conduct),
                          totalCredits: Value(semester.totalCredits),
                          creditsPassed: Value(semester.creditsPassed),
                          note: Value(semester.note),
                          gpa: Value(gpaBySemester[key]),
                        ),
                        onConflict: DoUpdate(
                          (old) => UserSemesterSummariesCompanion(
                            average: Value(semester.average),
                            conduct: Value(semester.conduct),
                            totalCredits: Value(semester.totalCredits),
                            creditsPassed: Value(semester.creditsPassed),
                            note: Value(semester.note),
                            gpa: Value(gpaBySemester[key]),
                          ),
                          target: [
                            _database.userSemesterSummaries.user,
                            _database.userSemesterSummaries.semester,
                          ],
                        ),
                      ))
                  .id;

          // TODO: Persist per-course scores via CourseRepository.getCourse()
          // to resolve course codes to proper Course rows before inserting
          // into the Scores table.

          await (_database.delete(_database.userSemesterRankings)..where(
                (t) => t.summary.equals(summaryId),
              ))
              .go();

          for (final ranking in rankingsBySemester[key] ?? const []) {
            await _database
                .into(_database.userSemesterRankings)
                .insert(
                  UserSemesterRankingsCompanion.insert(
                    summary: summaryId,
                    rankingType: ranking.type,
                    semesterRank: ranking.semesterRank,
                    semesterTotal: ranking.semesterTotal,
                    grandTotalRank: ranking.grandTotalRank,
                    grandTotalTotal: ranking.grandTotalTotal,
                  ),
                );
          }
        }
      }

      await (_database.update(_database.users)
            ..where((u) => u.id.equals(userId)))
          .write(UsersCompanion(scoreDataFetchedAt: Value(DateTime.now())));
    });

    return _buildSemesterRecordData(userId);
  }

  Future<List<SemesterRecordData>> _buildSemesterRecordData(
    int userId,
  ) async {
    final summaryRows =
        await (_database.select(_database.userAcademicSummaries)
              ..where((s) => s.user.equals(userId))
              ..orderBy([
                (s) => OrderingTerm.desc(s.year),
                (s) => OrderingTerm.desc(s.term),
              ]))
            .get();

    final records = <SemesterRecordData>[];
    for (final summary in summaryRows) {
      final scoreRows =
          await (_database.select(_database.scoreDetails)
                ..where(
                  (s) =>
                      s.user.equals(userId) &
                      s.semester.equals(summary.semester),
                )
                ..orderBy([(s) => OrderingTerm.asc(s.code)]))
              .get();

      final rankingRows =
          await (_database.select(_database.userSemesterRankings)..where(
                (r) => r.summary.equals(summary.id),
              ))
              .get();

      records.add((
        summary: summary,
        scores: scoreRows,
        rankings: rankingRows,
      ));
    }

    return records;
  }
}
