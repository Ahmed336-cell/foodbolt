import 'package:flutter/widgets.dart';
import 'package:foodbolt/l10n/app_localizations.dart';

import '../phase/room_phase.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension SelectionModeL10n on SelectionMode {
  String labelOf(AppLocalizations l10n) => switch (this) {
        SelectionMode.raceDirect => l10n.modeRaceDirect,
        SelectionMode.voteWithTieRace => l10n.modeVoteWithTieRace,
        SelectionMode.voteOnly => l10n.modeVoteOnly,
      };

  String subtitleOf(AppLocalizations l10n) => switch (this) {
        SelectionMode.raceDirect => l10n.modeRaceDirectHint,
        SelectionMode.voteWithTieRace => l10n.modeVoteWithTieRaceHint,
        SelectionMode.voteOnly => l10n.modeVoteOnlyHint,
      };

  String emoji() => switch (this) {
        SelectionMode.raceDirect => '🏁',
        SelectionMode.voteWithTieRace => '🗳️',
        SelectionMode.voteOnly => '✅',
      };
}

class AppLocales {
  AppLocales._();

  static const english = Locale('en');
  static const arabic = Locale('ar');
  static const supported = <Locale>[english, arabic];
}
