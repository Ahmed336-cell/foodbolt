import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/food_visuals.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../cubit/voting_cubit.dart';

class VotingFlowScreen extends StatelessWidget {
  const VotingFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VotingCubit, VotingState>(
      builder: (context, state) {
        return switch (state.stage) {
          1 => const _VotingDiscover(),
          2 => const _VotingActive(),
          _ => const _VotingResults(),
        };
      },
    );
  }
}

class _VotingDiscover extends StatelessWidget {
  const _VotingDiscover();

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<SuggestionCubit>().state.items;
    final voting = context.watch<VotingCubit>().state;
    final room = context.watch<RoomCubit>().state.room!;
    final roomId = room.id;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.chooseFavorite)),
      body: AdaptivePadding(
        bottom: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionPrompt(text: l10n.oneVote),
            const SizedBox(height: 4),
            Text(
              room.selectionMode == SelectionMode.voteWithTieRace
                  ? l10n.tieHint
                  : l10n.modeVoteOnlyHint,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            if (voting.error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: voting.error!),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: suggestions.isEmpty
                  ? EmptyStateView(message: l10n.noRestaurantsToVote)
                  : ListView.separated(
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = suggestions[i];
                        return _VoteCard(
                          name: s.name,
                          category: s.category,
                          subtitle: l10n.bySomeone(s.suggestedByName),
                          onVote: voting.loading
                              ? null
                              : () => context
                                  .read<VotingCubit>()
                                  .vote(roomId, s.id),
                        );
                      },
                    ),
            ),
            if (isHost) ...[
              const SizedBox(height: 12),
              _HostRevealButton(roomId: roomId, loading: voting.loading),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({
    required this.name,
    required this.category,
    required this.subtitle,
    required this.onVote,
  });

  final String name;
  final String? category;
  final String subtitle;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          FoodBadge(name: name, category: category),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(84, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onVote,
            child: Text(context.l10n.vote),
          ),
        ],
      ),
    );
  }
}

class _HostRevealButton extends StatelessWidget {
  const _HostRevealButton({required this.roomId, required this.loading});

  final String roomId;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final room = context.read<RoomCubit>().state.room!;
    final l10n = context.l10n;
    return PrimaryButton(
      label: l10n.revealWinner,
      loading: loading,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        final outcome = await context.read<VotingCubit>().reveal(roomId);
        if (outcome != null && outcome.isTie) {
          final races =
              room.selectionMode == SelectionMode.voteWithTieRace;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                races
                    ? l10n.tieSnack(outcome.tiedSuggestionIds.length)
                    : l10n.pickTiedWinner,
              ),
            ),
          );
        }
      },
    );
  }
}

class _VotingActive extends StatelessWidget {
  const _VotingActive();

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<SuggestionCubit>().state.items;
    final voting = context.watch<VotingCubit>().state;
    final snap = voting.snapshot;
    final selected =
        suggestions.where((s) => s.id == snap?.mySuggestionId).firstOrNull;
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final totalVotes = snap?.votes.length ?? 0;
    final members = context.watch<RoomCubit>().state.members.length;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourVote)),
      body: AdaptivePadding(
        bottom: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionPrompt(text: l10n.votedProgress(totalVotes, members)),
            if (voting.error != null) ...[
              const SizedBox(height: 12),
              ErrorBanner(message: voting.error!),
            ],
            const SizedBox(height: 12),
            if (selected != null)
              TweenAnimationBuilder<double>(
                key: ValueKey(selected.id),
                tween: Tween(begin: 0.85, end: 1),
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: FoodVisuals.gradientFor(selected.name),
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Text(
                        FoodVisuals.emojiFor(
                          name: selected.name,
                          category: selected.category,
                        ),
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.votedFor,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              selected.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: Colors.white),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              l10n.changeMind,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Expanded(
              child: ListView(
                children: suggestions
                    .where((s) => s.id != selected?.id)
                    .map(
                      (s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: FoodBadge(
                          name: s.name,
                          category: s.category,
                          size: 40,
                        ),
                        title: Text(s.name),
                        trailing: TextButton(
                          onPressed: voting.loading
                              ? null
                              : () => context
                                  .read<VotingCubit>()
                                  .vote(room.id, s.id),
                          child: Text(l10n.switchVote),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            if (isHost)
              _HostRevealButton(roomId: room.id, loading: voting.loading)
            else
              Text(
                l10n.waitingReveal,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _VotingResults extends StatelessWidget {
  const _VotingResults();

  @override
  Widget build(BuildContext context) {
    final suggestions = context.watch<SuggestionCubit>().state.items;
    final snap = context.watch<VotingCubit>().state.snapshot;
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final counts = snap?.counts ?? const <String, int>{};
    final ranked = [...suggestions]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
    final winner = ranked.where((s) => s.id == snap?.winnerId).firstOrNull;
    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce((a, b) => a > b ? a : b);
    final isTie = snap?.isTie ?? false;
    final tiedIds = snap?.tiedSuggestionIds ?? const <String>[];
    final voteOnlyTie =
        isTie && room.selectionMode == SelectionMode.voteOnly;
    final raceOnTie =
        isTie && room.selectionMode == SelectionMode.voteWithTieRace;
    final l10n = context.l10n;
    final voting = context.watch<VotingCubit>().state;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.results)),
      body: AdaptivePadding(
        bottom: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (voting.error != null) ErrorBanner(message: voting.error!),
            if (voteOnlyTie)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.pickTiedWinner,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.pickTiedWinnerHint,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            else if (raceOnTie)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8D6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🏁', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.tieBanner,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              )
            else if (winner != null)
              Column(
                children: [
                  Text(
                    l10n.winner,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  FoodBadge(
                    name: winner.name,
                    category: winner.category,
                    size: 64,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winner.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: ranked.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final s = ranked[i];
                  final count = counts[s.id] ?? 0;
                  final isTiedOption = tiedIds.contains(s.id);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('#${i + 1}  '),
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(l10n.votesCount(count)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: count / maxCount),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => LinearProgressIndicator(
                            value: value,
                            minHeight: 10,
                            backgroundColor: Colors.black12,
                            valueColor: AlwaysStoppedAnimation(
                              FoodVisuals.colorFor(s.name),
                            ),
                          ),
                        ),
                      ),
                      if (voteOnlyTie && isHost && isTiedOption) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton.icon(
                            onPressed: () => context
                                .read<VotingCubit>()
                                .pickTied(room.id, s.id),
                            icon: const Icon(Icons.emoji_events_outlined),
                            label: Text(l10n.hostPickWinner),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
