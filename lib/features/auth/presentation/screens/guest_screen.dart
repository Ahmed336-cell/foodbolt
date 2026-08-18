import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/avatar/app_avatars.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../deep_link/presentation/cubit/deep_link_cubit.dart';
import '../cubit/auth_cubit.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  late final AppAvatar _suggested = AppAvatars.random();
  late final TextEditingController _name;
  late String _avatarId;
  late String _lastSuggestedName;

  @override
  void initState() {
    super.initState();
    _avatarId = _suggested.id;
    _lastSuggestedName = _suggested.suggestedName;
    _name = TextEditingController(text: _lastSuggestedName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _selectAvatar(String id) {
    final next = AppAvatars.byId(id);
    setState(() {
      if (_name.text.trim() == _lastSuggestedName) {
        _name.text = next.suggestedName;
        _name.selection = TextSelection.collapsed(offset: _name.text.length);
      }
      _lastSuggestedName = next.suggestedName;
      _avatarId = next.id;
    });
  }

  void _shuffleName() {
    final next = AppAvatars.random();
    setState(() {
      _avatarId = next.id;
      _lastSuggestedName = next.suggestedName;
      _name.text = next.suggestedName;
      _name.selection = TextSelection.collapsed(offset: _name.text.length);
    });
  }

  Future<void> _continue() async {
    final extra = GoRouterState.of(context).extra;
    final pending = context.read<DeepLinkCubit>().state.pendingRoomId;
    final ok = await context.read<AuthCubit>().continueAsGuest(
          _name.text,
          avatar: _avatarId,
        );
    if (!ok || !mounted) return;
    if (pending != null) {
      context.go('/room/$pending');
      return;
    }
    if (extra == 'create') {
      context.go('/create-room');
    } else {
      context.go('/join-room');
    }
  }

  void _goBack() {
    final deepLink = context.read<DeepLinkCubit>();
    if (deepLink.state.pendingRoomId != null) {
      deepLink.setPending(null);
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = context.watch<DeepLinkCubit>().state.pendingRoomId;
    final extra = GoRouterState.of(context).extra;
    final fromInvite = pending != null;
    final creating = extra == 'create';
    final title = fromInvite
        ? l10n.guestJoinInviteTitle
        : creating
            ? l10n.createRoom
            : l10n.joinRoom;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AppScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionPrompt(
                  text: fromInvite ? l10n.guestJoinInviteTitle : l10n.guestTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  fromInvite
                      ? l10n.guestJoinInviteSubtitle
                      : l10n.guestEphemeralHint,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                if (state.error != null) ErrorBanner(message: state.error!),
                Text(l10n.pickAvatar, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                AvatarPicker(
                  selectedId: _avatarId,
                  onSelected: _selectAvatar,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: l10n.displayName,
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppTheme.primary,
                    ),
                    suffixIcon: IconButton(
                      tooltip: l10n.shuffleName,
                      onPressed: _shuffleName,
                      icon: const Icon(Icons.casino_outlined),
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: creating ? l10n.createRoom : l10n.joinRoom,
                  loading: state.loading,
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
