import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/room.dart';

abstract class RoomRepository {
  Future<Result<Room>> createRoom({
    required String name,
    required SelectionMode selectionMode,
    required RoomSettings settings,
  });
  Future<Result<Room>> joinRoom({required String code});
  Future<Result<Room>> joinRoomById({required String roomId});
  Future<Result<Room>> getRoom(String roomId);
  Future<Result<Room?>> getActiveRoomForCurrentUser();
  Future<Result<void>> leaveRoom(String roomId);
  Future<Result<Room>> setPhase({
    required String roomId,
    required RoomPhase phase,
  });
  Future<Result<Room>> setSelectionMode({
    required String roomId,
    required SelectionMode mode,
  });
  Future<Result<String>> getInviteLink(String roomId);
  Stream<Room> watchRoom(String roomId);
  Stream<List<RoomMember>> watchMembers(String roomId);
  Future<Result<List<Room>>> getHistory();
}
