import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/avatar/app_avatars.dart';
import '../../../../core/deep_link/invite_links.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/room/room_code.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';

class RoomSupabaseRepository implements RoomRepository {
  RoomSupabaseRepository(this._client);
  final SupabaseClient _client;
  final _rand = Random();

  @override
  Future<Result<Room>> createRoom({
    required String name,
    required SelectionMode selectionMode,
    required RoomSettings settings,
  }) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) {
      return const Failed(AuthFailure('Sign in to create a room.'));
    }
    try {
      final roomName = name.trim().isEmpty ? _funRoomName() : name.trim();
      final code = await _uniqueCode();
      final inserted = await _client
          .from('rooms')
          .insert({
            'code': code,
            'name': roomName,
            'host_id': userId,
            'phase': 'lobby',
            'selection_mode': SupabaseMappers.selectionModeToDb(selectionMode),
            'max_participants': settings.maxParticipants,
            'voting_duration_seconds': settings.votingDurationSeconds,
            'max_suggestions': settings.maxSuggestions,
            'allow_member_suggestions': settings.allowMemberSuggestions,
            'guest_access': settings.guestAccess,
            'vote_limit': settings.voteLimit,
          })
          .select()
          .single();

      final roomId = inserted['id'] as String;
      debugPrint('createRoom OK id=$roomId code=$code');
      final inviteUrl = InviteLinks.forToken(code);
      await _client.from('rooms').update({'invite_url': inviteUrl}).eq('id', roomId);

      await _client.from('room_members').insert({
        'room_id': roomId,
        'user_id': userId,
        'role': 'host',
        'is_online': true,
      });

      return Success(_mapRoom({...inserted, 'invite_url': inviteUrl}));
    } catch (e, st) {
      debugPrint('createRoom failed: $e\n$st');
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<Room>> joinRoom({required String code}) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) {
      return const Failed(AuthFailure('Sign in to join a room.'));
    }
    final normalized = RoomCode.extract(code);
    if (!RoomCode.isComplete(normalized)) {
      return const Failed(NotFoundFailure('Invalid room code.'));
    }
    try {
      final raw = await _client.rpc(
        'get_room_by_code',
        params: {'p_code': normalized},
      );
      Map<String, dynamic>? row;
      if (raw is List && raw.isNotEmpty && raw.first is Map) {
        row = Map<String, dynamic>.from(raw.first as Map);
      } else if (raw is Map) {
        row = Map<String, dynamic>.from(raw);
      }
      if (row == null) {
        return const Failed(NotFoundFailure('Invalid room code.'));
      }
      return _join(_mapRoom(row), userId);
    } catch (e, st) {
      final failure = SupabaseMappers.mapError(e, st);
      if (failure is NotFoundFailure) {
        return const Failed(NotFoundFailure('Invalid room code.'));
      }
      return Failed(failure);
    }
  }

  @override
  Future<Result<Room>> joinRoomById({required String roomId}) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) {
      return const Failed(AuthFailure('Sign in to join a room.'));
    }
    try {
      final row =
          await _client.from('rooms').select().eq('id', roomId).maybeSingle();
      if (row == null) {
        return const Failed(NotFoundFailure('Room not found.'));
      }
      return _join(_mapRoom(row), userId);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  Future<Result<Room>> _join(Room room, String userId) async {
    if (room.phase == RoomPhase.completed) {
      return const Failed(ValidationFailure('This room has already ended.'));
    }

    final profile = await _client
        .from('profiles')
        .select('is_guest')
        .eq('id', userId)
        .maybeSingle();
    final isGuest = profile?['is_guest'] as bool? ?? false;
    if (!room.settings.guestAccess && isGuest) {
      return const Failed(
        PermissionFailure('Guests are not allowed in this room.'),
      );
    }

    final existing = await _client
        .from('room_members')
        .select('user_id')
        .eq('room_id', room.id)
        .eq('user_id', userId)
        .maybeSingle();
    if (existing != null) {
      await _client
          .from('room_members')
          .update({'is_online': true})
          .eq('room_id', room.id)
          .eq('user_id', userId);
      return Success(room);
    }

    final countRes = await _client
        .from('room_members')
        .select('user_id')
        .eq('room_id', room.id);
    if ((countRes as List).length >= room.settings.maxParticipants) {
      return const Failed(ValidationFailure('Room is full.'));
    }

    await _client.from('room_members').insert({
      'room_id': room.id,
      'user_id': userId,
      'role': 'member',
      'is_online': true,
    });
    return Success(room);
  }

  @override
  Future<Result<Room>> getRoom(String roomId) async {
    try {
      final row =
          await _client.from('rooms').select().eq('id', roomId).maybeSingle();
      if (row == null) return const Failed(NotFoundFailure('Room not found.'));
      return Success(_mapRoom(row));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<void>> leaveRoom(String roomId) async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());
    try {
      await _client
          .from('room_members')
          .delete()
          .eq('room_id', roomId)
          .eq('user_id', userId);
      return const Success(null);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<Room>> setPhase({
    required String roomId,
    required RoomPhase phase,
  }) async {
    try {
      final updated = await _client
          .from('rooms')
          .update({'phase': SupabaseMappers.roomPhaseToDb(phase)})
          .eq('id', roomId)
          .select()
          .single();
      return Success(_mapRoom(updated));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<Room>> setSelectionMode({
    required String roomId,
    required SelectionMode mode,
  }) async {
    try {
      final updated = await _client
          .from('rooms')
          .update({'selection_mode': SupabaseMappers.selectionModeToDb(mode)})
          .eq('id', roomId)
          .select()
          .single();
      return Success(_mapRoom(updated));
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Future<Result<String>> getInviteLink(String roomId) async {
    try {
      final row = await _client
          .from('rooms')
          .select('invite_url, id, code')
          .eq('id', roomId)
          .maybeSingle();
      if (row == null) return const Failed(NotFoundFailure('Room not found.'));
      final existing = row['invite_url'] as String?;
      if (existing != null && existing.isNotEmpty) {
        return Success(existing);
      }
      final code = (row['code'] as String?) ?? row['id'] as String;
      final url = InviteLinks.forToken(code);
      await _client.from('rooms').update({'invite_url': url}).eq('id', roomId);
      return Success(url);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  @override
  Stream<Room> watchRoom(String roomId) {
    return _client
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((rows) {
          if (rows.isEmpty) {
            throw const NotFoundFailure('Room not found.');
          }
          return _mapRoom(rows.first);
        });
  }

  @override
  Stream<List<RoomMember>> watchMembers(String roomId) async* {
    // Join profiles for display fields; re-fetch on membership changes.
    Future<List<RoomMember>> load() async {
      final rows = await _client
          .from('room_members')
          .select(
            'user_id, role, is_online, joined_at, profiles(display_name, avatar, avatar_color, is_guest)',
          )
          .eq('room_id', roomId)
          .order('joined_at');
      return (rows as List)
          .map((raw) => _mapMember(Map<String, dynamic>.from(raw as Map)))
          .toList();
    }

    yield await load();
    await for (final _ in _client
        .from('room_members')
        .stream(primaryKey: ['room_id', 'user_id'])
        .eq('room_id', roomId)) {
      yield await load();
    }
  }

  @override
  Future<Result<List<Room>>> getHistory() async {
    final userId = SupabaseMappers.requireUserId(_client);
    if (userId == null) return const Failed(AuthFailure());
    try {
      final profile = await _client
          .from('profiles')
          .select('is_guest')
          .eq('id', userId)
          .maybeSingle();
      if (profile?['is_guest'] == true) return const Success([]);

      final memberships = await _client
          .from('room_members')
          .select('room_id')
          .eq('user_id', userId);
      final ids = (memberships as List)
          .map((e) => (e as Map)['room_id'] as String)
          .toList();
      if (ids.isEmpty) return const Success([]);

      final rows = await _client
          .from('rooms')
          .select()
          .inFilter('id', ids)
          .eq('phase', 'completed')
          .order('created_at', ascending: false);
      final rooms =
          (rows as List).map((r) => _mapRoom(Map<String, dynamic>.from(r as Map))).toList();
      return Success(rooms);
    } catch (e, st) {
      return Failed(SupabaseMappers.mapError(e, st));
    }
  }

  Room _mapRoom(Map<String, dynamic> row) {
    return Room(
      id: row['id'] as String,
      code: row['code'] as String,
      name: row['name'] as String,
      hostId: row['host_id'] as String,
      phase: SupabaseMappers.roomPhaseFromDb(row['phase'] as String?),
      selectionMode:
          SupabaseMappers.selectionModeFromDb(row['selection_mode'] as String?),
      settings: RoomSettings(
        maxParticipants: SupabaseMappers.asInt(row['max_participants'], 12),
        votingDurationSeconds:
            SupabaseMappers.asInt(row['voting_duration_seconds'], 60),
        maxSuggestions: SupabaseMappers.asInt(row['max_suggestions'], 8),
        allowMemberSuggestions:
            row['allow_member_suggestions'] as bool? ?? true,
        guestAccess: row['guest_access'] as bool? ?? true,
        voteLimit: SupabaseMappers.asInt(row['vote_limit'], 1),
      ),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      winnerSuggestionId: row['winner_suggestion_id'] as String?,
      inviteUrl: row['invite_url'] as String?,
    );
  }

  RoomMember _mapMember(Map<String, dynamic> row) {
    final profile = row['profiles'];
    final profileMap = profile is Map
        ? Map<String, dynamic>.from(profile)
        : <String, dynamic>{};
    return RoomMember(
      userId: row['user_id'] as String,
      displayName: profileMap['display_name'] as String? ?? 'User',
      avatar: AppAvatars.byId(profileMap['avatar'] as String?).id,
      role: (row['role'] as String?) == 'host' ? MemberRole.host : MemberRole.member,
      isGuest: profileMap['is_guest'] as bool? ?? false,
      isOnline: row['is_online'] as bool? ?? true,
      joinedAt: DateTime.tryParse(row['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Future<String> _uniqueCode() async {
    for (var i = 0; i < 12; i++) {
      final code = _generateCode();
      final existing = await _client
          .from('rooms')
          .select('id')
          .eq('code', code)
          .maybeSingle();
      if (existing == null) return code;
    }
    return _generateCode();
  }

  String _generateCode() {
    const chars = RoomCode.alphabet;
    return List.generate(
      RoomCode.length,
      (_) => chars[_rand.nextInt(chars.length)],
    ).join();
  }

  String _funRoomName() {
    const adjectives = ['Spicy', 'Crispy', 'Cheesy', 'Hungry', 'Midnight'];
    const nouns = ['Crew', 'Squad', 'Table', 'Feast', 'Hangout'];
    return '${adjectives[_rand.nextInt(adjectives.length)]} '
        '${nouns[_rand.nextInt(nouns.length)]}';
  }
}
