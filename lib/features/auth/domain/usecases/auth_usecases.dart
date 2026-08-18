import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser extends UseCase<AppUser?, NoParams> {
  GetCurrentUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser?>> call(NoParams params) => _repo.getCurrentUser();
}

class LoginUser extends UseCase<AppUser, LoginParams> {
  LoginUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser>> call(LoginParams params) =>
      _repo.login(email: params.email, password: params.password);
}

class LoginParams {
  const LoginParams({required this.email, required this.password});
  final String email;
  final String password;
}

class RegisterUser extends UseCase<SignUpCompleted, RegisterParams> {
  RegisterUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<SignUpCompleted>> call(RegisterParams params) => _repo.register(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
        avatar: params.avatar,
      );
}

class RegisterParams {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
    required this.avatar,
  });
  final String email;
  final String password;
  final String displayName;
  final String avatar;
}

class ContinueAsGuest extends UseCase<AppUser, GuestParams> {
  ContinueAsGuest(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<AppUser>> call(GuestParams params) => _repo.continueAsGuest(
        displayName: params.displayName,
        avatar: params.avatar,
      );
}

class GuestParams {
  const GuestParams({required this.displayName, required this.avatar});
  final String displayName;
  final String avatar;
}

class LogoutUser extends UseCase<void, NoParams> {
  LogoutUser(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<void>> call(NoParams params) => _repo.logout();
}

class DeleteAccount extends UseCase<void, NoParams> {
  DeleteAccount(this._repo);
  final AuthRepository _repo;

  @override
  Future<Result<void>> call(NoParams params) => _repo.deleteAccount();
}
