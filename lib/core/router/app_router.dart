import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/screens/guest_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/deep_link/presentation/cubit/deep_link_cubit.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/room/presentation/screens/create_room_screen.dart';
import '../../features/room/presentation/screens/home_screen.dart';
import '../../features/room/presentation/screens/join_room_screen.dart';
import '../../features/room/presentation/screens/room_session_screen.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../di/injection.dart';

GoRouter createRouter({String initialLocation = '/splash'}) {
  final authCubit = sl<AuthCubit>();
  final deepLinkCubit = sl<DeepLinkCubit>();
  final settingsCubit = sl<SettingsCubit>();

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: Listenable.merge([
      GoRouterRefreshStream(authCubit.stream),
      GoRouterRefreshStream(settingsCubit.stream),
      GoRouterRefreshStream(deepLinkCubit.stream),
    ]),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = authCubit.state;
      if (!auth.initialized && loc != '/splash') return '/splash';
      if (!auth.initialized) return null;

      final settings = settingsCubit.state;
      if (settings.loaded && !settings.onboardingSeen) {
        return loc == '/splash' || loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/onboarding') return '/welcome';

      final loggedIn = auth.isAuthenticated;
      final pending = deepLinkCubit.state.pendingRoomId;
      final onAuthGate =
          loc == '/welcome' ||
          loc == '/login' ||
          loc == '/guest' ||
          loc == '/splash';

      // Invite deep link while logged out → guest join flow.
      if (!loggedIn && pending != null) {
        if (loc == '/login' || loc == '/guest' || loc == '/splash') {
          return null;
        }
        return '/guest';
      }

      if (loggedIn && pending != null) {
        final target = '/room/$pending';
        if (loc != target) return target;
      }

      if (!loggedIn && !onAuthGate) return '/welcome';
      if (loggedIn &&
          (loc == '/welcome' || loc == '/login' || loc == '/guest')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/guest', builder: (_, __) => const GuestScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/create-room',
        builder: (_, __) => const CreateRoomScreen(),
      ),
      GoRoute(path: '/join-room', builder: (_, __) => const JoinRoomScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/join/:token',
        redirect: (context, state) {
          final token = state.pathParameters['token'];
          if (token == null || token.isEmpty) return '/home';
          unawaited(deepLinkCubit.setPending(token));
          return authCubit.state.isAuthenticated ? '/room/$token' : '/guest';
        },
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomSessionScreen(roomId: roomId);
        },
      ),
    ],
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
