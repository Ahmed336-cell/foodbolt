import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubit/room_cubit.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => sl<RoomCubit>(),
      child: BlocBuilder<RoomCubit, RoomState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.joinRoom)),
            body: AppScrollPage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionPrompt(text: l10n.enterRoomCode),
                  const SizedBox(height: 16),
                  if (state.error != null) ErrorBanner(message: state.error!),
                  TextField(
                    controller: _code,
                    textCapitalization: TextCapitalization.characters,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(hintText: l10n.roomCodeHint),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: l10n.joinRoom,
                    loading: state.loading,
                    onPressed: () async {
                      final room =
                          await context.read<RoomCubit>().joinWithCode(_code.text);
                      if (room != null && context.mounted) {
                        context.go('/room/${room.id}');
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
