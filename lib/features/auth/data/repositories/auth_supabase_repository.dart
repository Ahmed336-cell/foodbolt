import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthSupabaseRepository implements AuthRepository {
  AuthSupabaseRepository(this._client);
  final SupabaseClient _client;
  final _rand = Random();

  static const _avatarColors = <int>[
    0xFFE85D04,
    0xFF2D6A4F,
    0xFF1976D2,
    0xFF7B1FA2,
    0xFFC9184A,
    0xFFEF8354,
  ];

  @override
  Stream<AppUser?> watchAuth() async* {
    yield await _loadCurrent();
    await for (final event in _client.auth.onAuthStateChange) {
      if (event.session == null) {
        yield null;
      } else {
        yield await _loadCurrent();
      }
    }
  }

  @override
  Future<Result<AppUser?>> getCurrentUser() async {
    try {
      return Success(await _loadCurrent());
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<AppUser>> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return const Failed(ValidationFailure('Email and password required.'));
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) {
        return const Failed(AuthFailure('Login failed.'));
      }
      final profile = await _ensureProfile(
        userId: user.id,
        email: email.trim(),
        displayName: email.split('@').first,
        isGuest: false,
      );
      return Success(profile);
    } on AuthException catch (e, st) {
      return Failed(_mapAuthException(e, st));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<SignUpCompleted>> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (email.trim().isEmpty || password.isEmpty || displayName.trim().isEmpty) {
      return const Failed(ValidationFailure('All fields required.'));
    }
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      final user = res.user;
      if (user == null) {
        return const Failed(AuthFailure('Registration failed.'));
      }
      // Always require explicit login after sign-up (and email activate if enabled).
      if (_client.auth.currentSession != null) {
        await _client.auth.signOut();
      }
      return const Success(SignUpCompleted());
    } on AuthException catch (e, st) {
      return Failed(_mapAuthException(e, st));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  Failure _mapAuthException(AuthException error, [StackTrace? stackTrace]) {
    final code = error.code?.toLowerCase() ?? '';
    final message = error.message.toLowerCase();
    if (code == 'email_not_confirmed' ||
        message.contains('email not confirmed') ||
        message.contains('email_not_confirmed')) {
      return const AuthFailure(
        'Activate your account first before you can join.',
      );
    }
    return AuthFailure(error.message);
  }

  @override
  Future<Result<AppUser>> continueAsGuest({required String displayName}) async {
    final name = displayName.trim().isEmpty ? 'Guest' : displayName.trim();
    try {
      final res = await _client.auth.signInAnonymously(
        data: {'display_name': name, 'is_guest': true},
      );
      final user = res.user;
      if (user == null) {
        return const Failed(AuthFailure('Guest sign-in failed.'));
      }
      final profile = await _ensureProfile(
        userId: user.id,
        displayName: name,
        isGuest: true,
      );
      return Success(profile);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _client.auth.signOut();
      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      // SQL RPC is the supported path. Edge function is optional.
      await _client.rpc('delete_my_account');
      await _safeSignOut();
      return const Success(null);
    } catch (e, st) {
      debugPrint('deleteAccount failed: $e\n$st');
      // Keep session on failure so user sees the real error.
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  Future<void> _safeSignOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Account may already be gone — local session clear is enough.
    }
  }

  Future<AppUser?> _loadCurrent() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();
    if (row == null) {
      return _ensureProfile(
        userId: authUser.id,
        email: authUser.email,
        displayName: (authUser.userMetadata?['display_name'] as String?) ??
            authUser.email?.split('@').first ??
            'User',
        isGuest: authUser.isAnonymous ||
            authUser.userMetadata?['is_guest'] == true,
      );
    }
    return _mapProfile(row);
  }

  Future<AppUser> _ensureProfile({
    required String userId,
    required String displayName,
    String? email,
    required bool isGuest,
  }) async {
    final existing = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (existing != null) {
      // Refresh display name for guests who rename.
      if (isGuest && existing['display_name'] != displayName) {
        final updated = await _client
            .from('profiles')
            .update({'display_name': displayName})
            .eq('id', userId)
            .select()
            .single();
        return _mapProfile(updated);
      }
      return _mapProfile(existing);
    }

    final inserted = await _client
        .from('profiles')
        .insert({
          'id': userId,
          'display_name': displayName,
          'email': email,
          'is_guest': isGuest,
          'avatar_color': _avatarColors[_rand.nextInt(_avatarColors.length)],
        })
        .select()
        .single();
    return _mapProfile(inserted);
  }

  AppUser _mapProfile(Map<String, dynamic> row) {
    return AppUser(
      id: row['id'] as String,
      displayName: row['display_name'] as String? ?? 'User',
      email: row['email'] as String?,
      avatarColor: SupabaseMappers.asInt(row['avatar_color'], 0xFFE85D04),
      isGuest: row['is_guest'] as bool? ?? false,
    );
  }
}
