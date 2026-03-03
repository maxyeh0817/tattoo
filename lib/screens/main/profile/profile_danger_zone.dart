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

    final testerAction = ref.watch(testerActionProvider);

    return Column(
      spacing: 8,
      children: [
        SectionHeader(title: t.$wip('Danger Zone'), color: dangerColor),
        OptionEntryTile.icon(
          icon: Icons.sports_bar_outlined,
          title: '去酒吧$testerAction',
          color: dangerColor,
          borderColor: dangerColor,
          onTap: () {
            if (testerAction == '跑進吧檯被店員拖出去') {
              SystemNavigator.pop();
            } else {
              throw Exception('酒吧陷入火海');
            }
          },
        ),
        OptionEntryTile.icon(
          icon: Icons.bug_report_outlined,
          title: '非 Flutter 框架崩潰',
          color: dangerColor,
          borderColor: dangerColor,
          onTap: () {
            Future.delayed(Duration.zero, () {
              throw Exception('非框架崩潰');
            });
          },
        ),
      ],
    );
  }
}
