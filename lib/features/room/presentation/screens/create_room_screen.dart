import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/auth/guest_exit.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../domain/entities/room.dart';
import '../cubit/room_cubit.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _name = TextEditingController();
  SelectionMode _mode = SelectionMode.voteWithTieRace;
  bool _guestAccess = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      leaveToHomeOrOnboarding(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => sl<RoomCubit>(),
      child: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _dismiss();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.createRoom),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _dismiss,
                ),
              ),
              body: AppScrollPage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionPrompt(text: l10n.nameYourHangout),
                    const SizedBox(height: 12),
                    if (state.error != null) ErrorBanner(message: state.error!),
                    TextField(
                      controller: _name,
                      decoration: InputDecoration(hintText: l10n.roomNameHint),
                    ),
                    const SizedBox(height: 24),
                    SectionPrompt(text: l10n.howDecide),
                    const SizedBox(height: 12),
                    ...SelectionMode.values.map((mode) {
                      final selected = _mode == mode;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          color: selected
                              ? const Color(0xFFFFE8D6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => setState(() => _mode = mode),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mode.emoji(),
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mode.labelOf(l10n),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          mode.subtitleOf(l10n),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppTheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    SwitchListTile(
                      value: _guestAccess,
                      onChanged: (v) => setState(() => _guestAccess = v),
                      title: Text(l10n.allowGuests),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: l10n.createRoom,
                      loading: state.loading,
                      onPressed: () async {
                        final room = await context.read<RoomCubit>().create(
                              name: _name.text,
                              mode: _mode,
                              settings:
                                  RoomSettings(guestAccess: _guestAccess),
                            );
                        if (room != null && context.mounted) {
                          context.go('/room/${room.id}');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
