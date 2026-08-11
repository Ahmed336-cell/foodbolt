import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/race_state.dart';
import '../../domain/repositories/race_repository.dart';
import '../../domain/usecases/race_usecases.dart';

class RaceCubitState extends Equatable {
  const RaceCubitState({
    this.race,
    this.loading = false,
    this.error,
  });

  final RaceState? race;
  final bool loading;
  final String? error;

  RaceCubitState copyWith({
    RaceState? race,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return RaceCubitState(
      race: race ?? this.race,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [race, loading, error];
}

class RaceCubit extends Cubit<RaceCubitState> {
  RaceCubit({
    required RaceRepository repository,
    required PrepareRace prepareRace,
    required StartRace startRace,
  })  : _repository = repository,
        _prepareRace = prepareRace,
        _startRace = startRace,
        super(const RaceCubitState());

  final RaceRepository _repository;
  final PrepareRace _prepareRace;
  final StartRace _startRace;
  StreamSubscription<RaceState>? _sub;

  void watch(String roomId) {
    _sub?.cancel();
    _sub = _repository.watchRace(roomId).listen((race) {
      emit(state.copyWith(race: race));
    });
  }

  Future<bool> prepare(String roomId, {List<String>? candidateIds}) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _prepareRace(
      PrepareRaceParams(roomId: roomId, candidateIds: candidateIds),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (race) {
        emit(state.copyWith(race: race, loading: false));
        return true;
      },
    );
  }

  Future<bool> start(String roomId) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _startRace(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (race) {
        emit(state.copyWith(race: race, loading: false));
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
