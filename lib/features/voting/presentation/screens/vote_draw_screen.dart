import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/food_visuals.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../race/presentation/cubit/race_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../cubit/voting_cubit.dart';

/// Shown after a vote draw (vote + race mode) before the tiebreaker race.
class VoteDrawScreen extends StatelessWidget {
  const VoteDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final suggestions = context.watch<SuggestionCubit>().state.items;
    final race = context.watch<RaceCubit>().state.race;
    final voting = context.watch<VotingCubit>().state;
    final tiedIds = (race?.suggestionIds.isNotEmpty == true)
        ? race!.suggestionIds
        : (voting.snapshot?.tiedSuggestionIds ?? const <String>[]);
    final tied = suggestions.where((s) => tiedIds.contains(s.id)).toList();
    final counts = voting.snapshot?.counts ?? const <String, int>{};
    final l10n = context.l10n;
    final raceCubit = context.watch<RaceCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drawTitle)),
      body: AdaptivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFE8D6), Color(0xFFFFF3E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Text('🤝', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 8),
                  Text(
                    l10n.drawTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.drawSubtitle(tied.length),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionPrompt(text: l10n.tiedRestaurants),
            if (raceCubit.state.error != null)
              ErrorBanner(message: raceCubit.state.error!),
            const SizedBox(height: 8),
            Expanded(
              child: tied.isEmpty
                  ? EmptyStateView(message: l10n.tieBanner)
                  : ListView.separated(
                      itemCount: tied.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = tied[i];
                        final votes = counts[s.id] ?? 0;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: FoodVisuals.colorFor(s.name)
                                  .withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              FoodBadge(
                                name: s.name,
                                category: s.category,
                                size: 52,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    Text(
                                      l10n.votesCount(votes),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Text('🏁', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (isHost)
              PrimaryButton(
                label: l10n.goToRace,
                loading: raceCubit.state.loading,
                onPressed: () async {
                  await context.read<RaceCubit>().prepare(
                        room.id,
                        candidateIds: tiedIds.isEmpty ? null : tiedIds,
                      );
                },
              )
            else
              Text(
                l10n.waitingHostStartRace,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
