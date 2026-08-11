import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/payment_record.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/payment_usecases.dart';

class PaymentSummaryState extends Equatable {
  const PaymentSummaryState({
    this.payments = const [],
    this.loading = false,
    this.error,
  });

  final List<PaymentRecord> payments;
  final bool loading;
  final String? error;

  int get paidCount => payments.where((p) => p.paid).length;
  int get requestedCount =>
      payments.where((p) => p.status == PaymentStatus.requested).length;
  bool get everyonePaid =>
      payments.isNotEmpty && payments.every((p) => p.paid);

  PaymentSummaryState copyWith({
    List<PaymentRecord>? payments,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return PaymentSummaryState(
      payments: payments ?? this.payments,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [payments, loading, error];
}

class PaymentSummaryCubit extends Cubit<PaymentSummaryState> {
  PaymentSummaryCubit({
    required PaymentRepository repository,
    required RequestPayment requestPayment,
    required MarkPaymentAsPaid markPaymentAsPaid,
    required MarkPaymentAsUnpaid markPaymentAsUnpaid,
  })  : _repository = repository,
        _requestPayment = requestPayment,
        _markPaid = markPaymentAsPaid,
        _markUnpaid = markPaymentAsUnpaid,
        super(const PaymentSummaryState());

  final PaymentRepository _repository;
  final RequestPayment _requestPayment;
  final MarkPaymentAsPaid _markPaid;
  final MarkPaymentAsUnpaid _markUnpaid;
  StreamSubscription<List<PaymentRecord>>? _sub;
  String? _roomId;

  void watch(String roomId) {
    _roomId = roomId;
    _sub?.cancel();
    _sub = _repository.watchPayments(roomId).listen((payments) {
      emit(state.copyWith(payments: payments));
    });
  }

  Future<bool> requestPaid(String userId) async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _requestPayment(
      PaymentUserParams(roomId: roomId, userId: userId),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<bool> markPaid(String userId) async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result =
        await _markPaid(PaymentUserParams(roomId: roomId, userId: userId));
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<bool> markUnpaid(String userId) async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result =
        await _markUnpaid(PaymentUserParams(roomId: roomId, userId: userId));
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
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
