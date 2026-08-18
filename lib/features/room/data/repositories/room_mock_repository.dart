import '../../../../core/deep_link/invite_links.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/room/room_code.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';

class RoomMockRepository implements RoomRepository {
  RoomMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<Room>> createRoom({
    required String name,
    required SelectionMode selectionMode,
    required RoomSettings settings,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;

    final roomName = name.trim().isEmpty ? _store.funRoomName() : name.trim();
    final id = _store.newId();
    final code = _store.generateCode();
    final room = Room(
      id: id,
      code: code,
      name: roomName,
      hostId: user.id,
      phase: RoomPhase.lobby,
      selectionMode: selectionMode,
      settings: settings,
      createdAt: DateTime.now(),
      inviteUrl: InviteLinks.forToken(code),
    );
    _store.members[id] = [
      RoomMember(
        userId: user.id,
        displayName: user.displayName,
        avatar: user.avatar,
        role: MemberRole.host,
        isGuest: user.isGuest,
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    ];
    _store.suggestions[id] = [];
    _store.votes[id] = [];
    _store.orders[id] = [];
    _store.emitRoom(room);
    _store.emitMembers(id);
    return Success(room);
  }

  @override
  Future<Result<Room>> joinRoom({required String code}) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;

    final normalized = RoomCode.extract(code);
    if (!RoomCode.isComplete(normalized)) {
      return const Failed(NotFoundFailure('Invalid room code.'));
    }

    final room = _store.rooms.values
        .where((r) => RoomCode.normalize(r.code) == normalized)
        .firstOrNull;
    if (room == null) {
      return const Failed(NotFoundFailure('Invalid room code.'));
    }
    return _join(room, user);
  }

  @override
  Future<Result<Room>> joinRoomById({required String roomId}) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    return _join(roomResult.dataOrNull!, userResult.dataOrNull!);
  }

  Result<Room> _join(Room room, AppUser user) {
    if (room.phase == RoomPhase.completed) {
      return const Failed(ValidationFailure('This room has already ended.'));
    }
    if (!room.settings.guestAccess && user.isGuest) {
      return const Failed(PermissionFailure('Guests are not allowed in this room.'));
    }
    final list = _store.members[room.id] ?? [];
    if (list.any((m) => m.userId == user.id)) {
      return Success(room);
    }
    if (list.length >= room.settings.maxParticipants) {
      return const Failed(ValidationFailure('Room is full.'));
    }
    list.add(
      RoomMember(
        userId: user.id,
        displayName: user.displayName,
        avatar: user.avatar,
        role: MemberRole.member,
        isGuest: user.isGuest,
        isOnline: true,
        joinedAt: DateTime.now(),
      ),
    );
    _store.members[room.id] = list;
    _store.emitMembers(room.id);
    return Success(room);
  }

  @override
  Future<Result<Room>> getRoom(String roomId) async {
    return _store.requireRoom(roomId);
  }

  @override
  Future<Result<void>> leaveRoom(String roomId) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;
    final list = _store.members[roomId] ?? [];
    _store.members[roomId] = list.where((m) => m.userId != user.id).toList();
    _store.emitMembers(roomId);
    return const Success(null);
  }

  @override
  Future<Result<Room>> setPhase({
    required String roomId,
    required RoomPhase phase,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final updated = roomResult.dataOrNull!.copyWith(phase: phase);
    _store.emitRoom(updated);
    return Success(updated);
  }

  @override
  Future<Result<Room>> setSelectionMode({
    required String roomId,
    required SelectionMode mode,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final hostResult = _store.requireHost(roomId, userResult.dataOrNull!.id);
    if (hostResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final updated = roomResult.dataOrNull!.copyWith(selectionMode: mode);
    _store.emitRoom(updated);
    return Success(updated);
  }

  @override
  Future<Result<String>> getInviteLink(String roomId) async {
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;
    final url = room.inviteUrl ?? InviteLinks.forToken(room.code);
    return Success(url);
  }

  @override
  Stream<Room> watchRoom(String roomId) => _store.watchRoom(roomId);

  @override
  Stream<List<RoomMember>> watchMembers(String roomId) =>
      _store.watchMembers(roomId);

  @override
  Future<Result<List<Room>>> getHistory() async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final user = userResult.dataOrNull!;
    if (user.isGuest) return const Success([]);
    return Success(_store.historyForUser(user.id));
  }
}
