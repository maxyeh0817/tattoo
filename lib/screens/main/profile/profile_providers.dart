import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/database/database.dart';
import 'package:tattoo/repositories/auth_repository.dart';

import 'package:tattoo/i18n/strings.g.dart';

/// Provides the current user's profile.
///
/// Returns `null` if not logged in. Automatically fetches full profile if stale.
final userProfileProvider = FutureProvider.autoDispose<User?>((ref) {
  return ref.watch(authRepositoryProvider).getUser();
});

/// Provides the current user's avatar file.
///
/// Returns `null` if user has no avatar or not logged in.
final userAvatarProvider = FutureProvider.autoDispose<File?>((ref) {
  return ref.watch(authRepositoryProvider).getAvatar();
});

/// Provides the user's active registration (current class and semester).
///
/// Depends on [userProfileProvider] to ensure registration data is populated.
final activeRegistrationProvider =
    FutureProvider.autoDispose<UserRegistration?>((ref) async {
      await ref.watch(userProfileProvider.future);
      return ref.watch(authRepositoryProvider).getActiveRegistration();
    });

/// Provides a random tester action index.
final testerActionProvider =
    NotifierProvider.autoDispose<TesterActionNotifier, int>(
      TesterActionNotifier.new,
    );

class TesterActionNotifier extends Notifier<int> {
  @override
  int build() {
    final length = t.about.easter.actions.length;
    return Random().nextInt(length);
  }

  void refresh() {
    final length = t.about.easter.actions.length;
    state = Random().nextInt(length);
  }
}
