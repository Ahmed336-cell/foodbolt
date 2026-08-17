import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/restaurant_suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';

class SuggestionSupabaseRepository implements SuggestionRepository {
  SuggestionSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _channels = <String, RealtimeChannel>{};

  @override
  Future<Result<RestaurantSuggestion>> addSuggestion({
    required String roomId,
    required String name,
    String? category,
    String? note,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());

    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Failed(ValidationFailure('Restaurant name required.'));
    }

    try {
      final member = await _client
          .from('room_members')
          .select('role')
          .eq('room_id', roomId)
          .eq('user_id', userId)
          .maybeSingle();
      if (member == null) return const Failed(PermissionFailure());

      final room = await _client
          .from('rooms')
          .select(
            'host_id, allow_member_suggestions, max_suggestions',
          )
          .eq('id', roomId)
          .maybeSingle();
      if (room == null) return const Failed(NotFoundFailure());

      final isHost = room['host_id'] == userId;
      final allowMembers = room['allow_member_suggestions'] as bool? ?? true;
      if (!allowMembers && !isHost) {
        return const Failed(PermissionFailure());
      }

      final existing = await _client
          .from('suggestions')
          .select('id')
          .eq('room_id', roomId);
      final max = SupabaseMappers.asInt(room['max_suggestions'], 8);
      if ((existing as List).length >= max) {
        return const Failed(ValidationFailure('Suggestion limit reached.'));
      }

      final profile = await _client
          .from('profiles')
          .select('display_name')
          .eq('id', userId)
          .maybeSingle();

      final row = await _client
          .from('suggestions')
          .insert({
            'room_id': roomId,
            'name': trimmed,
            'category': category,
            'note': note,
            'suggested_by': userId,
          })
          .select()
          .single();

      final created = RestaurantSuggestion(
        id: row['id'] as String,
        roomId: roomId,
        name: row['name'] as String,
        category: row['category'] as String?,
        note: row['note'] as String?,
        imageUrl: row['image_url'] as String?,
        suggestedBy: userId,
        suggestedByName: profile?['display_name'] as String? ?? 'User',
      );
      await _broadcastChange(roomId);
      return Success(created);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> removeSuggestion({
    required String roomId,
    required String suggestionId,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure('Not signed in.'));
    final id = suggestionId.trim();
    if (id.isEmpty) {
      return const Failed(NotFoundFailure('Restaurant not found.'));
    }

    try {
      await _client.rpc('delete_suggestion', params: {'p_id': id});
      await _broadcastChange(roomId);
      return const Success(null);
    } catch (e, st) {
      if (_isMissingDeleteRpc(e)) {
        return _removeViaRest(
          roomId: roomId,
          suggestionId: id,
          userId: userId,
        );
      }
      final failure = SupabaseMappers.mapError(e, st);
      if (failure is NotFoundFailure) {
        await _broadcastChange(roomId);
        return const Failed(NotFoundFailure('Restaurant not found.'));
      }
      return Failed(failure);
    }
  }

  Future<Result<void>> _removeViaRest({
    required String roomId,
    required String suggestionId,
    required String userId,
  }) async {
    try {
      final rows = await _client
          .from('suggestions')
          .select('id, suggested_by, room_id')
          .eq('id', suggestionId)
          .limit(1);
      if (rows is! List || rows.isEmpty) {
        await _broadcastChange(roomId);
        return const Failed(NotFoundFailure('Restaurant not found.'));
      }
      final item = Map<String, dynamic>.from(rows.first as Map);
      final itemRoomId = item['room_id']?.toString();
      if (itemRoomId != null &&
          itemRoomId.isNotEmpty &&
          roomId.isNotEmpty &&
          itemRoomId != roomId) {
        return const Failed(NotFoundFailure('Restaurant not found.'));
      }

      final room = await _client
          .from('rooms')
          .select('host_id')
          .eq('id', itemRoomId ?? roomId)
          .limit(1);
      final hostId = room is List && room.isNotEmpty
          ? (room.first as Map)['host_id']?.toString()
          : null;
      final isHost = hostId == userId;
      if (item['suggested_by']?.toString() != userId && !isHost) {
        return const Failed(PermissionFailure());
      }

      try {
        await _client
            .from('rooms')
            .update({'winner_suggestion_id': null})
            .eq('winner_suggestion_id', suggestionId);
      } catch (_) {}
      try {
        await _client
            .from('races')
            .update({'winner_id': null})
            .eq('winner_id', suggestionId);
      } catch (_) {}

      await _client.from('suggestions').delete().eq('id', suggestionId);
      await _broadcastChange(roomId);
      return const Success(null);
    } catch (e, st) {
      final failure = SupabaseMappers.mapError(e, st);
      if (failure is NotFoundFailure) {
        return const Failed(NotFoundFailure('Restaurant not found.'));
      }
      return Failed(failure);
    }
  }

  bool _isMissingDeleteRpc(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('delete_suggestion') &&
        (text.contains('does not exist') ||
            text.contains('42883') ||
            text.contains('pgrst202') ||
            text.contains('could not find the function'));
  }

  @override
  Future<Result<List<RestaurantSuggestion>>> getSuggestions(
    String roomId,
  ) async {
    try {
      final list = await _loadSuggestions(roomId);
      return Success(list);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<List<RestaurantSuggestion>> watchSuggestions(String roomId) {
    late final StreamController<List<RestaurantSuggestion>> controller;
    StreamSubscription? pgSub;
    RealtimeChannel? channel;

    Future<void> push() async {
      if (controller.isClosed) return;
      try {
        controller.add(await _loadSuggestions(roomId));
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<RestaurantSuggestion>>(
      onListen: () {
        unawaited(push());
        pgSub = _client
            .from('suggestions')
            .stream(primaryKey: ['id'])
            .eq('room_id', roomId)
            .listen((_) => unawaited(push()), onError: (_) => unawaited(push()));

        channel = _client.channel('room-suggestions-$roomId');
        channel!
            .onBroadcast(
              event: 'suggestions',
              callback: (_) => unawaited(push()),
            )
            .subscribe();
        _channels[roomId] = channel!;
      },
      onCancel: () async {
        await pgSub?.cancel();
        await channel?.unsubscribe();
        _channels.remove(roomId);
      },
    );
    return controller.stream;
  }

  Future<void> _broadcastChange(String roomId) async {
    try {
      final channel =
          _channels[roomId] ?? _client.channel('room-suggestions-$roomId');
      await channel.sendBroadcastMessage(
        event: 'suggestions',
        payload: {'at': DateTime.now().millisecondsSinceEpoch},
      );
    } catch (_) {}
  }

  Future<List<RestaurantSuggestion>> _loadSuggestions(String roomId) async {
    final rows = await _client
        .from('suggestions')
        .select()
        .eq('room_id', roomId)
        .order('created_at');

    final votes = await _client
        .from('votes')
        .select('suggestion_id')
        .eq('room_id', roomId);
    final counts = <String, int>{};
    for (final v in votes as List) {
      final sid = v['suggestion_id'] as String;
      counts[sid] = (counts[sid] ?? 0) + 1;
    }

    final userIds = <String>{
      for (final r in rows as List) r['suggested_by'] as String,
    };
    final names = await _profileNames(userIds);

    final list = (rows as List).map((r) {
      final id = r['id'].toString();
      final by = r['suggested_by'].toString();
      return RestaurantSuggestion(
        id: id,
        roomId: roomId,
        name: r['name'] as String,
        category: r['category'] as String?,
        note: r['note'] as String?,
        imageUrl: r['image_url'] as String?,
        suggestedBy: by,
        suggestedByName: names[by] ?? 'User',
        voteCount: counts[id] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return List.unmodifiable(list);
  }

  Future<Map<String, String>> _profileNames(Set<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id, display_name')
        .inFilter('id', ids.toList());
    return {
      for (final r in rows as List)
        r['id'] as String: r['display_name'] as String? ?? 'User',
    };
  }
}
