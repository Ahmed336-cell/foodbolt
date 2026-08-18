import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';

/// Successful sign-up — user must activate (if required) and log in.
class SignUpCompleted {
  const SignUpCompleted();
}

abstract class AuthRepository {
  Stream<AppUser?> watchAuth();
  Future<Result<AppUser?>> getCurrentUser();
  Future<Result<AppUser>> login({required String email, required String password});
  Future<Result<SignUpCompleted>> register({
    required String email,
    required String password,
    required String displayName,
    required String avatar,
  });
  Future<Result<AppUser>> continueAsGuest({
    required String displayName,
    required String avatar,
  });
  Future<Result<void>> logout();
  Future<Result<void>> deleteAccount();
}
