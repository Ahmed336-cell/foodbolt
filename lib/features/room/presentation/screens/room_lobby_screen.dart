import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/room.dart';
import '../cubit/room_cubit.dart';

class RoomLobbyScreen extends StatelessWidget {
  const RoomLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state.user;
    final l10n = context.l10n;
    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        final room = state.room!;
        final isHost = state.isHost(auth?.id);
        final readyCount = state.members.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(room.name),
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
                Row(
                  children: [
                    Chip(
                      avatar: const Icon(Icons.group_outlined, size: 18),
                      label: Text('$readyCount'),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(l10n.roomCode(room.code)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: room.code));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.codeCopied)),
                        );
                      },
                    ),
                  ],
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
                          color: m.avatarColor,
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
                if (isHost) ...[
                  const SizedBox(height: 12),
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
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      l10n.hostWillStart,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
