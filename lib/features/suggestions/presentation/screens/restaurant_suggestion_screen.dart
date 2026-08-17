import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/food_categories.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/food_visuals.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../race/presentation/cubit/race_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../cubit/suggestion_cubit.dart';

class RestaurantSuggestionScreen extends StatefulWidget {
  const RestaurantSuggestionScreen({super.key});

  @override
  State<RestaurantSuggestionScreen> createState() =>
      _RestaurantSuggestionScreenState();
}

class _RestaurantSuggestionScreenState extends State<RestaurantSuggestionScreen> {
  Future<void> _add() async {
    final name = TextEditingController();
    final note = TextEditingController();
    final roomId = context.read<RoomCubit>().state.room!.id;
    String? categoryId;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final l10n = ctx.l10n;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        height: 4,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionPrompt(text: l10n.addRestaurant),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n.restaurantName,
                        prefixIcon: const Icon(
                          Icons.storefront_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.chooseCategory,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 96,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisExtent: 84,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: FoodCategory.all.length,
                        itemBuilder: (context, i) {
                          final category = FoodCategory.all[i];
                          return _CategoryTile(
                            category: category,
                            selected: categoryId == category.id,
                            onTap: () => setSheetState(
                              () => categoryId = category.id,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: note,
                      decoration: InputDecoration(
                        hintText: l10n.noteOptional,
                        prefixIcon: const Icon(
                          Icons.sticky_note_2_outlined,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: l10n.add,
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (ok == true && mounted) {
      await context.read<SuggestionCubit>().add(
            roomId: roomId,
            name: name.text,
            category: categoryId,
            note: note.text.isEmpty ? null : note.text,
          );
    }
  }

  Future<void> _continue() async {
    final room = context.read<RoomCubit>().state.room!;
    final items = context.read<SuggestionCubit>().state.items;
    if (items.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.needTwoRestaurants)),
      );
      return;
    }

    switch (room.selectionMode) {
      case SelectionMode.voteWithTieRace:
      case SelectionMode.voteOnly:
        await context.read<RoomCubit>().advancePhase(RoomPhase.voting);
      case SelectionMode.raceDirect:
        final raceCubit = context.read<RaceCubit>();
        final prepared = await raceCubit.prepare(room.id);
        if (prepared) await raceCubit.start(room.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == user?.id;
    final isRace = room.selectionMode == SelectionMode.raceDirect;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.suggestRestaurants)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: Text(l10n.addRestaurant),
      ),
      body: BlocBuilder<SuggestionCubit, SuggestionState>(
        builder: (context, state) {
          return AdaptivePadding(
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionPrompt(text: l10n.cravingPrompt),
                const SizedBox(height: 4),
                Text(
                  isRace ? l10n.raceHint : l10n.voteHint,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                if (state.error != null) ErrorBanner(message: state.error!),
                Expanded(
                  child: state.items.isEmpty
                      ? _EmptySuggestions()
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 90),
                          itemCount: state.items.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final s = state.items[i];
                            return _SuggestionCard(
                              name: s.name,
                              category: s.category,
                              note: s.note,
                              suggestedByName: s.suggestedByName,
                              canRemove:
                                  isHost || s.suggestedBy == user?.id,
                              onRemove: () => context
                                  .read<SuggestionCubit>()
                                  .remove(s.roomId, s.id),
                            );
                          },
                        ),
                ),
                if (isHost)
                  PrimaryButton(
                    label: isRace ? l10n.startRace : l10n.startVoting,
                    onPressed: _continue,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FoodCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.black12,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 24,
              color: selected ? Colors.white : AppTheme.primary,
            ),
            const SizedBox(height: 4),
            Text(category.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(
              category.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(AppAssets.emptyPlate, height: 190),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.emptySuggestions,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              context.l10n.emptySuggestionsHint,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.name,
    required this.category,
    required this.note,
    required this.suggestedByName,
    required this.canRemove,
    required this.onRemove,
  });

  final String name;
  final String? category;
  final String? note;
  final String suggestedByName;
  final bool canRemove;
  final VoidCallback onRemove;

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
                  [
                    if (category != null && category!.isNotEmpty)
                      FoodCategory.labelOf(context.l10n, category),
                    context.l10n.bySomeone(suggestedByName),
                  ].join(' · '),
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (note != null && note!.isNotEmpty)
                  Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
