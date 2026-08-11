import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../race/presentation/cubit/race_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';

/// Legacy mid-flow mode picker (mode is normally chosen at create-room).
class VoteModeSelectionScreen extends StatefulWidget {
  const VoteModeSelectionScreen({super.key, required this.roomId});
  final String roomId;

  @override
  State<VoteModeSelectionScreen> createState() =>
      _VoteModeSelectionScreenState();
}

class _VoteModeSelectionScreenState extends State<VoteModeSelectionScreen> {
  SelectionMode? _selected;

  Future<void> _continue() async {
    final roomCubit = context.read<RoomCubit>();
    final raceCubit = context.read<RaceCubit>();
    await roomCubit.updateSelectionMode(_selected!);
    if (_selected == SelectionMode.raceDirect) {
      final prepared = await raceCubit.prepare(widget.roomId);
      if (prepared) await raceCubit.start(widget.roomId);
    } else {
      await roomCubit.advancePhase(RoomPhase.voting);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.howDecide)),
      body: AdaptivePadding(
        bottom: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionPrompt(text: l10n.cravingPrompt),
            const SizedBox(height: 16),
            for (final mode in SelectionMode.values) ...[
              _ModeCard(
                selected: _selected == mode,
                title: mode.labelOf(l10n),
                subtitle: mode.subtitleOf(l10n),
                emoji: mode.emoji(),
                image: mode == SelectionMode.raceDirect
                    ? AppAssets.raceBanner
                    : null,
                onTap: () => setState(() => _selected = mode),
              ),
              const SizedBox(height: 12),
            ],
            const Spacer(),
            PrimaryButton(
              label: l10n.continueLabel,
              onPressed: _selected == null ? null : _continue,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.onTap,
    this.image,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final String emoji;
  final String? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFE8D6) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              if (image != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Image.asset(
                    image!,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 30)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
