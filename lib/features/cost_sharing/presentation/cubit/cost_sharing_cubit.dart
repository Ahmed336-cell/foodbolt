import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/cost_share.dart';
import '../../domain/repositories/cost_sharing_repository.dart';
import '../../domain/usecases/cost_sharing_usecases.dart';

class CostSharingState extends Equatable {
  const CostSharingState({
    this.draft,
    this.extras = const AdditionalCosts(),
    this.receiptTotal = 0,
    this.loading = false,
    this.error,
  });

  final CostShareDraft? draft;
  final AdditionalCosts extras;
  final double receiptTotal;
  final bool loading;
  final String? error;

  CostSharingState copyWith({
    CostShareDraft? draft,
    AdditionalCosts? extras,
    double? receiptTotal,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return CostSharingState(
      draft: draft ?? this.draft,
      extras: extras ?? this.extras,
      receiptTotal: receiptTotal ?? this.receiptTotal,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [draft, extras, receiptTotal, loading, error];
}

class CostSharingCubit extends Cubit<CostSharingState> {
  CostSharingCubit({
    required CostSharingRepository repository,
    required CalculateCostSharing calculateCostSharing,
    required ConfirmCostSharing confirmCostSharing,
  })  : _repository = repository,
        _calculate = calculateCostSharing,
        _confirm = confirmCostSharing,
        super(const CostSharingState());

  final CostSharingRepository _repository;
  final CalculateCostSharing _calculate;
  final ConfirmCostSharing _confirm;
  StreamSubscription<CostShareDraft>? _sub;
  String? _roomId;

  void watch(String roomId, {double? initialTotal}) {
    _roomId = roomId;
    if (initialTotal != null) {
      emit(state.copyWith(receiptTotal: initialTotal));
    }
    _sub?.cancel();
    _sub = _repository.watchCostShare(roomId).listen((draft) {
      emit(
        state.copyWith(
          draft: draft,
          receiptTotal: draft.receiptTotal,
          extras: draft.additionalCosts,
        ),
      );
    });
  }

  void updateExtras(AdditionalCosts extras) {
    emit(state.copyWith(extras: extras));
  }

  void updateReceiptTotal(double total) {
    emit(state.copyWith(receiptTotal: total));
  }

  Future<bool> recalculate() async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _calculate(
      CalculateCostParams(
        roomId: roomId,
        receiptTotal: state.receiptTotal,
        additionalCosts: state.extras,
      ),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (draft) {
        emit(state.copyWith(draft: draft, loading: false));
        return true;
      },
    );
  }

  Future<bool> confirm() async {
    final roomId = _roomId;
    if (roomId == null) return false;
    await recalculate();
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _confirm(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (draft) {
        emit(state.copyWith(draft: draft, loading: false));
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
