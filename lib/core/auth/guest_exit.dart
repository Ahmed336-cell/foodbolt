import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';

/// Guests leave to welcome (create / join / login). Signed-in users go home.
Future<void> leaveToHomeOrOnboarding(BuildContext context) async {
  final guest = context.read<AuthCubit>().state.isGuest;
  if (!guest) {
    context.go('/home');
    return;
  }
  await context.read<AuthCubit>().logout();
  if (context.mounted) context.go('/welcome');
}
