import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/race_state.dart';
import '../../domain/race_duration.dart';
import '../../domain/repositories/race_repository.dart';

class RaceSupabaseRepository implements RaceRepository {
  RaceSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _rand = Random();

  @override
  Future<Result<RaceState>> prepareRace(
    String roomId, {
    List<String>? candidateIds,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != userId) {
        return const Failed(PermissionFailure());
      }

      final existingRace = await _client
          .from('races')
          .select('suggestion_ids, status')
          .eq('room_id', roomId)
          .maybeSingle();

      List<String>? pendingTiebreak;
      if (existingRace != null &&
          existingRace['status'] == 'idle' &&
          SupabaseMappers.asStringList(existingRace['suggestion_ids'])
                  .length >=
              2) {
        pendingTiebreak =
            SupabaseMappers.asStringList(existingRace['suggestion_ids']);
      }

      final requested = candidateIds ?? pendingTiebreak;
      final suggestionRows = await _client
          .from('suggestions')
          .select('id')
          .eq('room_id', roomId);
      final all = (suggestionRows as List)
          .map((r) => r['id'] as String)
          .toList();
      final ids = (requested == null || requested.length < 2)
          ? all
          : all.where(requested.contains).toList();

      if (ids.length < 2) {
        return const Failed(ValidationFailure('Need at least 2 restaurants.'));
      }

      final isTiebreaker = requested != null && requested.length >= 2;
      final winnerId = ids[_rand.nextInt(ids.length)];
      final state = RaceState(
        roomId: roomId,
        suggestionIds: ids,
        status: RaceStatus.countdown,
        winnerId: winnerId,
        isTiebreaker: isTiebreaker,
      );

      await _client.from('races').upsert({
        'room_id': roomId,
        'suggestion_ids': ids,
        'winner_id': winnerId,
        'status': SupabaseMappers.raceStatusToDb(RaceStatus.countdown),
        'is_tiebreaker': isTiebreaker,
      });

      await _client.from('rooms').update({
        'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.race),
        'winner_suggestion_id': winnerId,
      }).eq('id', roomId);

      return Success(state);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<RaceState>> startRace(String roomId) async {
    try {
      var row = await _client
          .from('races')
          .select()
          .eq('room_id', roomId)
          .maybeSingle();

      if (row == null || row['winner_id'] == null) {
        final prepared = await prepareRace(roomId);
        if (prepared case Failed(:final failure)) return Failed(failure);
        row = await _client
            .from('races')
            .select()
            .eq('room_id', roomId)
            .single();
      }

      final current = _mapRace(row);
      if (current.status == RaceStatus.racing ||
          current.status == RaceStatus.finished) {
        return Success(current);
      }

      await _client.from('races').update({
        'status': SupabaseMappers.raceStatusToDb(RaceStatus.racing),
      }).eq('room_id', roomId);

      final state = current.copyWith(status: RaceStatus.racing);

      // Client finishes race after animation duration (no DB trigger required).
      Future<void>.delayed(raceDuration, () async {
        try {
          await _client.from('races').update({
            'status': SupabaseMappers.raceStatusToDb(RaceStatus.finished),
          }).eq('room_id', roomId);

          if (state.winnerId != null) {
            await _client.from('rooms').update({
              'winner_suggestion_id': state.winnerId,
            }).eq('id', roomId);
          }
        } catch (_) {
          // Host/client may have already finished; ignore.
        }
      });

      return Success(state);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<RaceState> watchRace(String roomId) {
    return _client
        .from('races')
        .stream(primaryKey: ['room_id'])
        .eq('room_id', roomId)
        .map((rows) {
          if (rows.isEmpty) {
            return RaceState(
              roomId: roomId,
              suggestionIds: const [],
              status: RaceStatus.idle,
            );
          }
          return _mapRace(rows.first);
        });
  }

  RaceState _mapRace(Map<String, dynamic> row) {
    return RaceState(
      roomId: row['room_id'] as String,
      suggestionIds: SupabaseMappers.asStringList(row['suggestion_ids']),
      status: SupabaseMappers.raceStatusFromDb(row['status'] as String?),
      winnerId: row['winner_id'] as String?,
      isTiebreaker: row['is_tiebreaker'] as bool? ?? false,
    );
  }
}
