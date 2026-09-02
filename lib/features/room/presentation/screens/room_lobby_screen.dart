import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/auth/guest_exit.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/room_code_pin_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/room.dart';
import '../cubit/room_cubit.dart';

class RoomLobbyScreen extends StatelessWidget {
  const RoomLobbyScreen({super.key});

  Future<void> _leaveOrCancel(BuildContext context, {required bool isHost}) async {
    final l10n = context.l10n;
    final confirmed = await showAppConfirmDialog(
      context,
      title: isHost ? l10n.cancelRoomTitle : l10n.leaveRoomTitle,
      message: isHost ? l10n.cancelRoomBody : l10n.leaveRoomBody,
      confirmLabel: isHost ? l10n.cancelRoom : l10n.leaveRoom,
      icon: Icons.logout_rounded,
      variant: AppDialogVariant.destructive,
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await context.read<RoomCubit>().leave(isHost: isHost);
    if (ok && context.mounted) {
      await leaveToHomeOrOnboarding(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state.user;
    final l10n = context.l10n;
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        final room = state.room!;
        final isHost = state.isHost(auth?.id);
        final readyCount = state.members.length;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _leaveOrCancel(context, isHost: isHost);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(room.name),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: isHost ? l10n.cancelRoom : l10n.leaveRoom,
                onPressed: () => _leaveOrCancel(context, isHost: isHost),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () async {
                    final link = await context.read<RoomCubit>().inviteLink();
                    if (link != null) {
                      await SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${l10n.inviteMessage(room.name, room.code)}\n$link',
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            body: AdaptivePadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.roomCodeLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: room.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.codeCopied)),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: RoomCodePinDisplay(code: room.code),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapCodeToCopy,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: Chip(
                      avatar: const Icon(Icons.group_outlined, size: 18),
                      label: Text('$readyCount'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionPrompt(
                    text: isHost
                        ? (readyCount < 2
                            ? l10n.waitingForFriends
                            : l10n.playersReady(readyCount))
                        : l10n.waitingForHostStart,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = state.members[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          tileColor: Colors.white,
                          leading: AvatarCircle(
                            name: m.displayName,
                            avatar: m.avatar,
                          ),
                          title: Text(m.displayName),
                          subtitle: Text(
                            [
                              if (m.role == MemberRole.host) l10n.host,
                              if (m.isGuest) l10n.guest,
                              m.isOnline ? l10n.online : l10n.offline,
                            ].join(' · '),
                          ),
                        );
                      },
                    ),
                  ),

                  if (isHost) ...[
                    PrimaryButton(
                      label: l10n.start,
                      loading: state.loading,
                      onPressed: () async {
                        final confirmed = await showAppConfirmDialog(
                          context,
                          title: l10n.startGameQuestion,
                          message: readyCount < 2
                              ? l10n.startAnyway(readyCount)
                              : l10n.playersReady(readyCount),
                          confirmLabel: l10n.start,
                          icon: Icons.play_arrow_rounded,
                        );
                        if (confirmed == true && context.mounted) {
                          await context.read<RoomCubit>().startGame();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    SecondaryButton(
                      label: l10n.inviteFriends,
                      onPressed: () async {
                        final link = await context.read<RoomCubit>().inviteLink();
                        if (link != null) {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                              '${l10n.inviteMessage(room.name, room.code)}\n$link',
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: state.loading
                          ? null
                          : () => _leaveOrCancel(context, isHost: true),
                      child: Text(l10n.cancelRoom,style: TextStyle(color: AppTheme.textSecondary),),
                    ),
                  ] else ...[

                    PrimaryButton(
                      label: l10n.inviteFriends,
                      onPressed: () async {
                        final link = await context.read<RoomCubit>().inviteLink();
                        if (link != null) {
                          await SharePlus.instance.share(
                            ShareParams(
                              text:
                              '${l10n.inviteMessage(room.name, room.code)}\n$link',
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        l10n.hostWillStart,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: state.loading
                          ? null
                          : () => _leaveOrCancel(context, isHost: false),
                      child: Text(l10n.leaveRoom ,style: TextStyle(color: AppTheme.textPrimary),),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
