import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/vote.dart';
import '../../domain/repositories/voting_repository.dart';
import '../../domain/usecases/voting_usecases.dart';

class VotingState extends Equatable {
  const VotingState({
    this.snapshot,
    this.loading = false,
    this.error,
    this.stage = 1,
  });

  final VotingSnapshot? snapshot;
  final bool loading;
  final String? error;
  final int stage;

  VotingState copyWith({
    VotingSnapshot? snapshot,
    bool? loading,
    String? error,
    int? stage,
    bool clearError = false,
  }) {
    return VotingState(
      snapshot: snapshot ?? this.snapshot,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      stage: stage ?? this.stage,
    );
  }

  @override
  List<Object?> get props => [snapshot, loading, error, stage];
}

class VotingCubit extends Cubit<VotingState> {
  VotingCubit({
    required VotingRepository repository,
    required VoteRestaurant voteRestaurant,
    required RevealVoteWinner revealVoteWinner,
    required PickTiedWinner pickTiedWinner,
  })  : _repository = repository,
        _voteRestaurant = voteRestaurant,
        _revealVoteWinner = revealVoteWinner,
        _pickTiedWinner = pickTiedWinner,
        super(const VotingState());

  final VotingRepository _repository;
  final VoteRestaurant _voteRestaurant;
  final RevealVoteWinner _revealVoteWinner;
  final PickTiedWinner _pickTiedWinner;
  StreamSubscription<VotingSnapshot>? _sub;

  void watch(String roomId) {
    _sub?.cancel();
    _sub = _repository.watchVoting(roomId).listen((snapshot) {
      final stage = snapshot.revealed
          ? 3
          : snapshot.mySuggestionId != null
              ? 2
              : 1;
      emit(state.copyWith(snapshot: snapshot, stage: stage));
    });
  }

  void setStage(int stage) => emit(state.copyWith(stage: stage));

  Future<bool> vote(String roomId, String suggestionId) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _voteRestaurant(
      VoteParams(roomId: roomId, suggestionId: suggestionId),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false, stage: 2));
        return true;
      },
    );
  }

  Future<VoteRevealOutcome?> reveal(String roomId) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _revealVoteWinner(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return null;
      },
      (outcome) {
        emit(state.copyWith(loading: false, stage: 3));
        return outcome;
      },
    );
  }

  Future<bool> pickTied(String roomId, String suggestionId) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _pickTiedWinner(
      PickTiedWinnerParams(roomId: roomId, suggestionId: suggestionId),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false, stage: 3));
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
