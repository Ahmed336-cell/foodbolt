import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  void watch(String roomId) {
    _sub?.cancel();
    _sub = _repository.watchSuggestions(roomId).listen((items) {
      emit(state.copyWith(items: items));
    });
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
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<void> remove(String roomId, String suggestionId) async {
    final result = await _removeSuggestion(
      RemoveSuggestionParams(roomId: roomId, suggestionId: suggestionId),
    );
    result.fold((f) => emit(state.copyWith(error: f.message)), (_) {});
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
