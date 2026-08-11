import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../domain/usecases/receipt_usecases.dart';

class ReceiptState extends Equatable {
  const ReceiptState({
    this.receipt,
    this.localPath,
    this.totalText = '',
    this.loading = false,
    this.error,
    this.success = false,
  });

  final Receipt? receipt;
  final String? localPath;
  final String totalText;
  final bool loading;
  final String? error;
  final bool success;

  bool get wasSkipped => receipt?.status == ReceiptStatus.skipped;

  ReceiptState copyWith({
    Receipt? receipt,
    String? localPath,
    String? totalText,
    bool? loading,
    String? error,
    bool? success,
    bool clearError = false,
    bool clearPath = false,
  }) {
    return ReceiptState(
      receipt: receipt ?? this.receipt,
      localPath: clearPath ? null : (localPath ?? this.localPath),
      totalText: totalText ?? this.totalText,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      success: success ?? this.success,
    );
  }

  @override
  List<Object?> get props =>
      [receipt, localPath, totalText, loading, error, success];
}

class ReceiptCubit extends Cubit<ReceiptState> {
  ReceiptCubit({
    required ReceiptRepository repository,
    required UploadReceipt uploadReceipt,
    required SkipReceipt skipReceipt,
  })  : _repository = repository,
        _uploadReceipt = uploadReceipt,
        _skipReceipt = skipReceipt,
        super(const ReceiptState());

  final ReceiptRepository _repository;
  final UploadReceipt _uploadReceipt;
  final SkipReceipt _skipReceipt;
  StreamSubscription<Receipt>? _sub;
  String? _roomId;

  void watch(String roomId) {
    _roomId = roomId;
    _sub?.cancel();
    _sub = _repository.watchReceipt(roomId).listen((receipt) {
      emit(state.copyWith(receipt: receipt));
    });
  }

  void setImage(String path) => emit(state.copyWith(localPath: path));
  void clearImage() => emit(state.copyWith(clearPath: true));
  void setTotal(String value) => emit(state.copyWith(totalText: value));

  Future<bool> upload() async {
    final roomId = _roomId;
    final path = state.localPath;
    if (roomId == null || path == null) {
      emit(state.copyWith(error: 'Select a receipt image first.'));
      return false;
    }
    final total = double.tryParse(state.totalText.replaceAll(',', ''));
    if (total == null) {
      emit(state.copyWith(error: 'Enter a valid receipt total.'));
      return false;
    }
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _uploadReceipt(
      UploadReceiptParams(roomId: roomId, localPath: path, totalAmount: total),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (receipt) {
        emit(state.copyWith(receipt: receipt, loading: false, success: true));
        return true;
      },
    );
  }

  Future<bool> skip() async {
    final roomId = _roomId;
    if (roomId == null) {
      emit(state.copyWith(error: 'Room not ready.'));
      return false;
    }
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _skipReceipt(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (receipt) {
        emit(state.copyWith(receipt: receipt, loading: false, success: true));
        return true;
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
