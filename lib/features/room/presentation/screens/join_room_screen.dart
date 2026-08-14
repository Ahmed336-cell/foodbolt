import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/room/room_code.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/room_code_pin_field.dart';
import '../cubit/room_cubit.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  String _code = '';
  var _joining = false;

  void _dismiss() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _join(BuildContext context, String code) async {
    final normalized = RoomCode.extract(code);
    if (!RoomCode.isComplete(normalized) || _joining) return;
    setState(() {
      _code = normalized;
      _joining = true;
    });
    final room = await context.read<RoomCubit>().joinWithCode(normalized);
    if (!context.mounted) return;
    setState(() => _joining = false);
    if (room != null) {
      context.go('/room/${room.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canJoin = RoomCode.isComplete(_code);
    return BlocProvider(
      create: (_) => sl<RoomCubit>(),
      child: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          final busy = state.loading || _joining;
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _dismiss();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(l10n.joinRoom),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _dismiss,
                ),
              ),
              body: AppScrollPage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionPrompt(text: l10n.enterRoomCode),
                    const SizedBox(height: 8),
                    Text(
                      l10n.roomCodeHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF6B6B6B)),
                    ),
                    const SizedBox(height: 20),
                    if (state.error != null) ...[
                      ErrorBanner(message: state.error!),
                      const SizedBox(height: 12),
                    ],
                    RoomCodePinField(
                      enabled: !busy,
                      onChanged: (code) => setState(() => _code = code),
                      onCompleted: (code) => _join(context, code),
                    ),
                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: l10n.joinRoom,
                      loading: busy,
                      onPressed:
                          canJoin && !busy ? () => _join(context, _code) : null,
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
