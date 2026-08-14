import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.info,
    this.initialized = false,
  });

  final AppUser? user;
  final bool loading;
  final String? error;
  final String? info;
  final bool initialized;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AppUser? user,
    bool? loading,
    String? error,
    String? info,
    bool? initialized,
    bool clearUser = false,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      info: clearInfo ? null : (info ?? this.info),
      initialized: initialized ?? this.initialized,
    );
  }

  @override
  List<Object?> get props => [user, loading, error, info, initialized];
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository authRepository,
    required GetCurrentUser getCurrentUser,
    required LoginUser loginUser,
    required RegisterUser registerUser,
    required ContinueAsGuest continueAsGuest,
    required LogoutUser logoutUser,
    required DeleteAccount deleteAccount,
  })  : _getCurrentUser = getCurrentUser,
        _loginUser = loginUser,
        _registerUser = registerUser,
        _continueAsGuest = continueAsGuest,
        _logoutUser = logoutUser,
        _deleteAccount = deleteAccount,
        super(const AuthState()) {
    _sub = authRepository.watchAuth().listen((user) {
      emit(state.copyWith(user: user, clearUser: user == null, initialized: true));
    });
  }

  final GetCurrentUser _getCurrentUser;
  final LoginUser _loginUser;
  final RegisterUser _registerUser;
  final ContinueAsGuest _continueAsGuest;
  final LogoutUser _logoutUser;
  final DeleteAccount _deleteAccount;
  late final StreamSubscription<AppUser?> _sub;

  Future<void> checkSession() async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(loading: false, error: f.message, initialized: true)),
      (user) => emit(
        state.copyWith(
          user: user,
          clearUser: user == null,
          loading: false,
          initialized: true,
        ),
      ),
    );
  }

  Future<bool> login(String email, String password) async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    final result = await _loginUser(LoginParams(email: email, password: password));
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (user) {
        emit(state.copyWith(user: user, loading: false, clearInfo: true));
        return true;
      },
    );
  }

  /// Returns true when account was created — caller should switch to login.
  Future<bool> register(String email, String password, String name) async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    final result = await _registerUser(
      RegisterParams(email: email, password: password, displayName: name),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(
          state.copyWith(
            clearUser: true,
            loading: false,
            clearError: true,
            info:
                'Account created. Activate your email if required, then log in.',
          ),
        );
        return true;
      },
    );
  }

  Future<bool> continueAsGuest(String name) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _continueAsGuest(name);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (user) {
        emit(state.copyWith(user: user, loading: false));
        return true;
      },
    );
  }

  Future<void> logout() async {
    await _logoutUser(const NoParams());
    emit(state.copyWith(clearUser: true, clearError: true));
  }

  Future<bool> deleteAccount() async {
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    final result = await _deleteAccount(const NoParams());
    if (result case Failed(:final failure)) {
      emit(state.copyWith(loading: false, error: failure.message));
      return false;
    }
    // Always finish logged out (clears any leftover session).
    await _logoutUser(const NoParams());
    emit(
      state.copyWith(
        clearUser: true,
        loading: false,
        clearError: true,
        info: 'Account deleted successfully.',
      ),
    );
    return true;
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
