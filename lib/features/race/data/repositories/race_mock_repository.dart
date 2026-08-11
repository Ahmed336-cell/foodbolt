import 'dart:math';

import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/race_state.dart';
import '../../domain/race_duration.dart';
import '../../domain/repositories/race_repository.dart';

class RaceMockRepository implements RaceRepository {
  RaceMockRepository(this._store);
  final MockAppStore _store;
  final _rand = Random();

  @override
  Future<Result<RaceState>> prepareRace(
    String roomId, {
    List<String>? candidateIds,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);

    final pendingTiebreak = _store.tiebreakCandidates[roomId];
    final requested = candidateIds ?? pendingTiebreak;
    final all = (_store.suggestions[roomId] ?? []).map((s) => s.id).toList();
    final ids = (requested == null || requested.length < 2)
        ? all
        : all.where(requested.contains).toList();

    if (ids.length < 2) {
      return const Failed(ValidationFailure('Need at least 2 restaurants.'));
    }

    // Authoritative winner chosen once here — clients only animate toward it.
    final winnerId = ids[_rand.nextInt(ids.length)];
    final state = RaceState(
      roomId: roomId,
      suggestionIds: ids,
      status: RaceStatus.countdown,
      winnerId: winnerId,
      isTiebreaker: requested != null && requested.length >= 2,
    );
    _store.emitRoom(
      roomResult.dataOrNull!.copyWith(
        phase: RoomPhase.race,
        winnerSuggestionId: winnerId,
      ),
    );
    _store.emitRace(state);
    return Success(state);
  }

  @override
  Future<Result<RaceState>> startRace(String roomId) async {
    final existing = _store.races[roomId];
    if (existing == null || existing.winnerId == null) {
      final prepared = await prepareRace(roomId);
      if (prepared case Failed(:final failure)) return Failed(failure);
    }
    final current = _store.races[roomId]!;
    if (current.status == RaceStatus.racing ||
        current.status == RaceStatus.finished) {
      return Success(current);
    }
    final state = current.copyWith(status: RaceStatus.racing);
    _store.emitRace(state);

    // Winner is already decided; this only flips the shared status.
    Future<void>.delayed(raceDuration, () {
      final finished = state.copyWith(status: RaceStatus.finished);
      _store.emitRace(finished);
      _store.tiebreakCandidates.remove(roomId);
      final room = _store.rooms[roomId];
      if (room != null) {
        // Phase stays on race so everyone sees the celebration; the host
        // moves the room forward with the "Let's Order" action.
        _store.emitRoom(room.copyWith(winnerSuggestionId: finished.winnerId));
      }
    });
    return Success(state);
  }

  @override
  Stream<RaceState> watchRace(String roomId) => _store.watchRace(roomId);
}
