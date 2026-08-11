import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong. Try again.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([
    super.message = "You don't have permission to perform this action.",
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class OfflineFailure extends Failure {
  const OfflineFailure([
    super.message = "You're offline. Changes will sync when connection returns.",
  ]);
}
