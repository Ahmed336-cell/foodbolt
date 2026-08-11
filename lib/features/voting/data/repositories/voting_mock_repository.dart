import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../race/domain/entities/race_state.dart';
import '../../domain/entities/vote.dart';
import '../../domain/repositories/voting_repository.dart';

class VotingMockRepository implements VotingRepository {
  VotingMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<void>> castVote({
    required String roomId,
    required String suggestionId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;
    final memberResult = _store.requireMember(roomId, user.id);
    if (memberResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;
    if (room.phase != RoomPhase.voting) {
      return const Failed(ValidationFailure('Voting is not open.'));
    }
    final list = List<Vote>.from(_store.votes[roomId] ?? []);
    final mine = list.where((v) => v.userId == user.id).length;
    if (mine >= room.settings.voteLimit) {
      list.removeWhere((v) => v.userId == user.id);
    }
    list.add(Vote(roomId: roomId, userId: user.id, suggestionId: suggestionId));
    _store.votes[roomId] = list;
    _store.emitVotes(roomId);
    _store.emitSuggestions(roomId);
    return const Success(null);
  }

  @override
  Future<Result<VoteRevealOutcome>> revealWinner(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;

    final snapshot = _store.buildVotingSnapshot(roomId);
    if (snapshot.counts.isEmpty) {
      return const Failed(ValidationFailure('No votes yet.'));
    }

    final topCount = snapshot.counts.values.reduce((a, b) => a > b ? a : b);
    final tied = snapshot.counts.entries
        .where((e) => e.value == topCount)
        .map((e) => e.key)
        .toList();

    _store.voteRevealed[roomId] = true;

    if (tied.length > 1) {
      _store.tiebreakCandidates[roomId] = tied;
      _store.emitVotes(roomId);

      if (room.selectionMode.racesOnTie) {
        // Vote + race on draw → show draw screen first, then race.
        _store.emitRace(
          RaceState(
            roomId: roomId,
            suggestionIds: tied,
            status: RaceStatus.idle,
            isTiebreaker: true,
          ),
        );
        _store.emitRoom(room.copyWith(phase: RoomPhase.draw, clearWinner: true));
        return Success(VoteRevealOutcome(tiedSuggestionIds: tied));
      }

      // Vote only → stay on results; host must pick among tied.
      return Success(VoteRevealOutcome(tiedSuggestionIds: tied));
    }

    final winnerId = tied.first;
    _store.tiebreakCandidates.remove(roomId);
    _store.emitRoom(
      room.copyWith(
        winnerSuggestionId: winnerId,
        phase: RoomPhase.restaurantSelected,
      ),
    );
    _store.emitVotes(roomId);
    return Success(VoteRevealOutcome(winnerId: winnerId));
  }

  @override
  Future<Result<VoteRevealOutcome>> pickTiedWinner({
    required String roomId,
    required String suggestionId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;

    if (room.selectionMode != SelectionMode.voteOnly) {
      return const Failed(
        ValidationFailure('Host pick is only for vote-only rooms.'),
      );
    }

    final tied = _store.tiebreakCandidates[roomId] ?? const <String>[];
    if (!tied.contains(suggestionId)) {
      return const Failed(
        ValidationFailure('Pick one of the tied restaurants.'),
      );
    }

    _store.tiebreakCandidates.remove(roomId);
    _store.voteRevealed[roomId] = true;
    _store.emitRoom(
      room.copyWith(
        winnerSuggestionId: suggestionId,
        phase: RoomPhase.restaurantSelected,
      ),
    );
    _store.emitVotes(roomId);
    return Success(VoteRevealOutcome(winnerId: suggestionId));
  }

  @override
  Stream<VotingSnapshot> watchVoting(String roomId) => _store.watchVotes(roomId);
}
