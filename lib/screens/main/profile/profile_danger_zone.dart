import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tattoo/components/option_entry_tile.dart';
import 'package:tattoo/components/section_header.dart';
import 'package:tattoo/i18n/strings.g.dart';
import 'package:tattoo/repositories/preferences_repository.dart';
import 'package:tattoo/screens/main/profile/profile_providers.dart';

class ProfileDangerZone extends ConsumerWidget {
  const ProfileDangerZone({super.key});

  static const Color dangerColor = Colors.red;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(isBarEnabledProvider).asData?.value ?? false)) {
      return const SizedBox.shrink();
    }

    final testerActionIndex = ref.watch(testerActionProvider);
    final testerAction = t.about.easter.actions[testerActionIndex];

    return Column(
      spacing: 8,
      children: [
        SectionHeader(title: t.profile.sections.dangerZone, color: dangerColor),
        OptionEntryTile.icon(
          icon: Icons.sports_bar_outlined,
          title: t.about.easter.goBar(action: testerAction),
          color: dangerColor,
          borderColor: dangerColor,
          onTap: () {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(t.about.easter.barTitle),
                content: Text(
                  testerActionIndex == t.about.easter.actions.length - 1
                      ? t.about.easter.barKicked
                      : t.about.easter.barClosed,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(t.general.ok),
                  ),
                ],
              ),
            );
          },
        ),
        OptionEntryTile.icon(
          icon: Icons.bug_report_outlined,
          title: t.profile.dangerZone.nonFlutterCrash,
          color: dangerColor,
          borderColor: dangerColor,
          onTap: () {
            Future.delayed(Duration.zero, () {
              throw Exception(t.profile.dangerZone.nonFlutterCrashException);
            });
          },
        ),
      ],
    );
  }
}
