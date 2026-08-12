import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../deep_link/presentation/cubit/deep_link_cubit.dart';
import '../cubit/auth_cubit.dart';

class GuestScreen extends StatefulWidget {
  const GuestScreen({super.key});

  @override
  State<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends State<GuestScreen> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final extra = GoRouterState.of(context).extra;
    final pending = context.read<DeepLinkCubit>().state.pendingRoomId;
    final ok = await context.read<AuthCubit>().continueAsGuest(_name.text);
    if (!ok || !mounted) return;
    // Pending invite: router redirects to /room/:id after auth.
    if (pending != null) {
      context.go('/room/$pending');
      return;
    }
    if (extra == 'create') {
      context.go('/create-room');
    } else if (extra == 'join') {
      context.go('/join-room');
    } else {
      context.go('/home');
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
    final fromInvite = pending != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fromInvite ? l10n.guestJoinInviteTitle : l10n.continueAsGuest,
        ),
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
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.secondary, AppTheme.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Text('👋', style: TextStyle(fontSize: 30)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🍕 🍔 🌮',
                          style: TextStyle(fontSize: 22, letterSpacing: 4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SectionPrompt(
                  text: fromInvite ? l10n.guestJoinInviteTitle : l10n.guestTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  fromInvite
                      ? l10n.guestJoinInviteSubtitle
                      : l10n.guestSubtitle,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                if (state.error != null) ErrorBanner(message: state.error!),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    hintText: l10n.displayName,
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: AppTheme.primary,
                    ),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: fromInvite ? l10n.joinRoom : l10n.continueLabel,
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
