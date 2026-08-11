import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/vote.dart';
import '../../domain/repositories/voting_repository.dart';

class VotingSupabaseRepository implements VotingRepository {
  VotingSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Result<void>> castVote({
    required String roomId,
    required String suggestionId,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final member = await _client
          .from('room_members')
          .select('user_id')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (member == null) return const Failed(PermissionFailure());

      final room = await _client
          .from('rooms')
          .select('phase, vote_limit')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (SupabaseMappers.roomPhaseFromDb(room['phase'] as String?) !=
          RoomPhase.voting) {
        return const Failed(ValidationFailure('Voting is not open.'));
      }

      final voteLimit = SupabaseMappers.asInt(room['vote_limit'], 1);
      final mine = await _client
          .from('votes')
          .select('suggestion_id')
          .eq('room_id', roomId)
          .eq('user_id', userId);

      if ((mine as List).length >= voteLimit) {
        await _client
            .from('votes')
            .delete()
            .eq('room_id', roomId)
            .eq('user_id', userId);
      }

      await _client.from('votes').insert({
        'room_id': roomId,
        'user_id': userId,
        'suggestion_id': suggestionId,
      });
      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<VoteRevealOutcome>> revealWinner(String roomId) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id, selection_mode, phase')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != userId) {
        return const Failed(PermissionFailure());
      }

      final voteRows = await _client
          .from('votes')
          .select('suggestion_id')
          .eq('room_id', roomId);
      final counts = <String, int>{};
      for (final v in voteRows as List) {
        final sid = v['suggestion_id'] as String;
        counts[sid] = (counts[sid] ?? 0) + 1;
      }
      if (counts.isEmpty) {
        return const Failed(ValidationFailure('No votes yet.'));
      }

      final topCount = counts.values.reduce((a, b) => a > b ? a : b);
      final tied = counts.entries
          .where((e) => e.value == topCount)
          .map((e) => e.key)
          .toList();

      final mode = SupabaseMappers.selectionModeFromDb(
        room['selection_mode'] as String?,
      );

      if (tied.length > 1) {
        // Persist tied candidates on races row (idle).
        await _client.from('races').upsert({
          'room_id': roomId,
          'suggestion_ids': tied,
          'winner_id': null,
          'status': 'idle',
          'is_tiebreaker': true,
        });

        if (mode.racesOnTie) {
          await _client.from('rooms').update({
            'phase': SupabaseMappers.roomPhaseToDb(RoomPhase.draw),
            'winner_suggestion_id': null,
          }).eq('id', roomId);
          return Success(VoteRevealOutcome(tiedSuggestionIds: tied));
        }

        // voteOnly — stay on voting; host picks among tied.
        return Success(VoteRevealOutcome(tiedSuggestionIds: tied));
      }

      final winnerId = tied.first;
      await _client.from('rooms').update({
        'winner_suggestion_id': winnerId,
        'phase':
            SupabaseMappers.roomPhaseToDb(RoomPhase.restaurantSelected),
      }).eq('id', roomId);

      return Success(VoteRevealOutcome(winnerId: winnerId));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<VoteRevealOutcome>> pickTiedWinner({
    required String roomId,
    required String suggestionId,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    try {
      final room = await _client
          .from('rooms')
          .select('host_id, selection_mode')
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());
      if (room['host_id'] != userId) {
        return const Failed(PermissionFailure());
      }

      final mode = SupabaseMappers.selectionModeFromDb(
        room['selection_mode'] as String?,
      );
      if (mode != SelectionMode.voteOnly) {
        return const Failed(
          ValidationFailure('Host pick is only for vote-only rooms.'),
        );
      }

      final race = await _client
          .from('races')
          .select('suggestion_ids, status')
          .eq('room_id', roomId)
          .maybeSingle();
      final tied = SupabaseMappers.asStringList(race?['suggestion_ids']);
      if (!tied.contains(suggestionId)) {
        return const Failed(
          ValidationFailure('Pick one of the tied restaurants.'),
        );
      }

      await _client.from('rooms').update({
        'winner_suggestion_id': suggestionId,
        'phase':
            SupabaseMappers.roomPhaseToDb(RoomPhase.restaurantSelected),
      }).eq('id', roomId);

      return Success(VoteRevealOutcome(winnerId: suggestionId));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<VotingSnapshot> watchVoting(String roomId) {
    late StreamController<VotingSnapshot> controller;
    final subs = <StreamSubscription<dynamic>>[];

    Future<void> push() async {
      if (controller.isClosed) return;
      try {
        controller.add(await _buildSnapshot(roomId));
      } catch (_) {
        // Ignore transient stream errors; next event retries.
      }
    }

    controller = StreamController<VotingSnapshot>(
      onListen: () {
        push();
        subs.add(
          _client
              .from('votes')
              .stream(primaryKey: ['room_id', 'user_id', 'suggestion_id'])
              .eq('room_id', roomId)
              .listen((_) => push()),
        );
        subs.add(
          _client
              .from('rooms')
              .stream(primaryKey: ['id'])
              .eq('id', roomId)
              .listen((_) => push()),
        );
        subs.add(
          _client
              .from('races')
              .stream(primaryKey: ['room_id'])
              .eq('room_id', roomId)
              .listen((_) => push()),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
        await controller.close();
      },
    );

    return controller.stream;
  }

  Future<VotingSnapshot> _buildSnapshot(String roomId) async {
    final userId = _client.auth.currentUser?.id;
    final voteRows = await _client
        .from('votes')
        .select('room_id, user_id, suggestion_id')
        .eq('room_id', roomId);

    final votes = (voteRows as List)
        .map(
          (v) => Vote(
            roomId: v['room_id'] as String,
            userId: v['user_id'] as String,
            suggestionId: v['suggestion_id'] as String,
          ),
        )
        .toList();

    final counts = <String, int>{};
    for (final v in votes) {
      counts[v.suggestionId] = (counts[v.suggestionId] ?? 0) + 1;
    }

    String? mine;
    if (userId != null) {
      mine = votes
          .where((v) => v.userId == userId)
          .map((v) => v.suggestionId)
          .firstOrNull;
    }

    final room = await _client
        .from('rooms')
        .select('winner_suggestion_id, phase, selection_mode')
        .eq('id', roomId)
        .maybeSingle();

    final race = await _client
        .from('races')
        .select('suggestion_ids, status, winner_id')
        .eq('room_id', roomId)
        .maybeSingle();

    final winnerId = room?['winner_suggestion_id'] as String?;
    final phase = SupabaseMappers.roomPhaseFromDb(room?['phase'] as String?);
    final tiedFromRace = SupabaseMappers.asStringList(race?['suggestion_ids']);
    final raceStatus = race?['status'] as String?;

    // Only treat as revealed during/after an actual vote reveal — not merely
    // because room phase is still lobby/suggestions while this stream is open.
    final voteOnlyTiePending = phase == RoomPhase.voting &&
        race != null &&
        raceStatus == 'idle' &&
        tiedFromRace.length > 1 &&
        winnerId == null;

    final revealed = winnerId != null || voteOnlyTiePending;

    final tied = voteOnlyTiePending ? tiedFromRace : const <String>[];

    return VotingSnapshot(
      roomId: roomId,
      votes: List.unmodifiable(votes),
      counts: counts,
      mySuggestionId: mine,
      winnerId: winnerId,
      revealed: revealed,
      tiedSuggestionIds: List.unmodifiable(tied),
    );
  }
}
