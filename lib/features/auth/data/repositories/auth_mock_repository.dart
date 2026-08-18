import '../../../../core/avatar/app_avatars.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthMockRepository implements AuthRepository {
  AuthMockRepository(this._store);
  final MockAppStore _store;

  @override
  Stream<AppUser?> watchAuth() => _store.authStream;

  @override
  Future<Result<AppUser?>> getCurrentUser() async => Success(_store.currentUser);

  @override
  Future<Result<AppUser>> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.isEmpty) {
      return const Failed(ValidationFailure('Email and password required.'));
    }
    final existing = _store.users.values
        .where((u) => u.email == email && !u.isGuest)
        .firstOrNull;
    final user = existing ??
        AppUser(
          id: _store.newId(),
          displayName: email.split('@').first,
          email: email,
          avatar: AppAvatars.defaultId,
          isGuest: false,
        );
    _store.setCurrentUser(user);
    return Success(user);
  }

  @override
  Future<Result<SignUpCompleted>> register({
    required String email,
    required String password,
    required String displayName,
    required String avatar,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      return const Failed(ValidationFailure('All fields required.'));
    }
    final user = AppUser(
      id: _store.newId(),
      displayName: displayName,
      email: email,
      avatar: AppAvatars.byId(avatar).id,
      isGuest: false,
    );
    _store.users[user.id] = user;
    _store.setCurrentUser(null);
    return const Success(SignUpCompleted());
  }

  @override
  Future<Result<AppUser>> continueAsGuest({
    required String displayName,
    required String avatar,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final name = displayName.trim().isEmpty ? 'Guest' : displayName.trim();
    final user = AppUser(
      id: _store.newId(),
      displayName: name,
      avatar: AppAvatars.byId(avatar).id,
      isGuest: true,
    );
    _store.setCurrentUser(user);
    return Success(user);
  }

  @override
  Future<Result<void>> logout() async {
    _store.setCurrentUser(null);
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final user = _store.currentUser;
    if (user == null) {
      return const Failed(AuthFailure('Not signed in.'));
    }
    _store.users.remove(user.id);
    _store.setCurrentUser(null);
    return const Success(null);
  }
}
