import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/restaurant_suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';
import '../../domain/usecases/suggestion_usecases.dart';

class SuggestionState extends Equatable {
  const SuggestionState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<RestaurantSuggestion> items;
  final bool loading;
  final String? error;

  SuggestionState copyWith({
    List<RestaurantSuggestion>? items,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return SuggestionState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [items, loading, error];
}

class SuggestionCubit extends Cubit<SuggestionState> {
  SuggestionCubit({
    required SuggestionRepository repository,
    required AddRestaurantSuggestion addSuggestion,
    required RemoveRestaurantSuggestion removeSuggestion,
  })  : _repository = repository,
        _addSuggestion = addSuggestion,
        _removeSuggestion = removeSuggestion,
        super(const SuggestionState());

  final SuggestionRepository _repository;
  final AddRestaurantSuggestion _addSuggestion;
  final RemoveRestaurantSuggestion _removeSuggestion;
  StreamSubscription<List<RestaurantSuggestion>>? _sub;
  final _removing = <String>{};
  String? _watchedRoomId;

  void watch(String roomId) {
    _watchedRoomId = roomId;
    _sub?.cancel();
    _sub = _repository.watchSuggestions(roomId).listen(
      (items) {
        emit(state.copyWith(items: items));
      },
      onError: (_) {
        unawaited(_refresh(roomId));
      },
    );
    unawaited(_refresh(roomId));
  }

  Future<void> _refresh(String roomId) async {
    final result = await _repository.getSuggestions(roomId);
    if (isClosed || _watchedRoomId != roomId) return;
    result.fold((_) {}, (items) => emit(state.copyWith(items: items)));
  }

  Future<bool> add({
    required String roomId,
    required String name,
    String? category,
    String? note,
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _addSuggestion(
      AddSuggestionParams(
        roomId: roomId,
        name: name,
        category: category,
        note: note,
      ),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (item) {
        emit(
          state.copyWith(
            loading: false,
            items: [
              ...state.items.where((s) => s.id != item.id),
              item,
            ],
          ),
        );
        return true;
      },
    );
  }

  Future<void> remove(String roomId, String suggestionId) async {
    if (!_removing.add(suggestionId)) return;
    final previous = state.items;
    emit(
      state.copyWith(
        clearError: true,
        items: previous.where((s) => s.id != suggestionId).toList(),
      ),
    );
    try {
      final result = await _removeSuggestion(
        RemoveSuggestionParams(roomId: roomId, suggestionId: suggestionId),
      );
      final failed = result.fold<Failure?>((f) => f, (_) => null);
      if (failed != null && !_alreadyGone(failed)) {
        emit(state.copyWith(items: previous, error: failed.message));
        return;
      }
      await _refresh(roomId);
    } finally {
      _removing.remove(suggestionId);
    }
  }

  bool _alreadyGone(Failure failure) {
    if (failure is NotFoundFailure) return true;
    final message = failure.message.toLowerCase();
    return message.contains('not found') || message.contains('0 rows');
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
