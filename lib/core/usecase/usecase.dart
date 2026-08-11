import 'package:equatable/equatable.dart';

import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Result<Type>> call(Params params);
}

abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

sealed class Result<T> {
  const Result();

  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess);

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failed<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failureOrNull => this is Failed<T> ? (this as Failed<T>).failure : null;
}

class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) =>
      onSuccess(data);
}

class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;

  @override
  R fold<R>(R Function(Failure failure) onFailure, R Function(T data) onSuccess) =>
      onFailure(failure);
}
