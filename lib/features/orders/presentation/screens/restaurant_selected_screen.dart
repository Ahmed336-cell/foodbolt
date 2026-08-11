import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/food_visuals.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';

class RestaurantSelectedScreen extends StatelessWidget {
  const RestaurantSelectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final members = context.watch<RoomCubit>().state.members;
    final winner = context
        .watch<SuggestionCubit>()
        .state
        .items
        .where((s) => s.id == room.winnerSuggestionId)
        .firstOrNull;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: AdaptivePadding(
          top: 8,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Image.asset(AppAssets.winnerPodium, height: 200),
                      const SizedBox(height: 8),
                      Text(
                        l10n.orderingTonightFrom,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      FoodBadge(
                        name: winner?.name ?? '?',
                        category: winner?.category,
                        size: 72,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        winner?.name ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(
                          l10n.viaMode(room.selectionMode.labelOf(l10n)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        children: members
                            .map(
                              (m) => AvatarCircle(
                                name: m.displayName,
                                color: m.avatarColor,
                                size: 38,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (isHost)
                PrimaryButton(
                  label: l10n.startOrdering,
                  onPressed: () => context
                      .read<RoomCubit>()
                      .advancePhase(RoomPhase.ordering),
                )
              else
                Text(
                  l10n.waitingHostOrdering,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
