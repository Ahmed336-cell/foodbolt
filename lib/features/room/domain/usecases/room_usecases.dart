import '../../../../core/phase/room_phase.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/room.dart';
import '../repositories/room_repository.dart';

class CreateRoom extends UseCase<Room, CreateRoomParams> {
  CreateRoom(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(CreateRoomParams params) => _repo.createRoom(
        name: params.name,
        selectionMode: params.selectionMode,
        settings: params.settings,
      );
}

class CreateRoomParams {
  const CreateRoomParams({
    required this.name,
    required this.selectionMode,
    required this.settings,
  });
  final String name;
  final SelectionMode selectionMode;
  final RoomSettings settings;
}

class JoinRoom extends UseCase<Room, String> {
  JoinRoom(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(String code) => _repo.joinRoom(code: code);
}

class JoinRoomById extends UseCase<Room, String> {
  JoinRoomById(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(String roomId) =>
      _repo.joinRoomById(roomId: roomId);
}

class GetRoom extends UseCase<Room, String> {
  GetRoom(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(String roomId) => _repo.getRoom(roomId);
}

class SetRoomPhase extends UseCase<Room, SetPhaseParams> {
  SetRoomPhase(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(SetPhaseParams params) =>
      _repo.setPhase(roomId: params.roomId, phase: params.phase);
}

class SetPhaseParams {
  const SetPhaseParams({required this.roomId, required this.phase});
  final String roomId;
  final RoomPhase phase;
}

class SetRoomSelectionMode extends UseCase<Room, SetModeParams> {
  SetRoomSelectionMode(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<Room>> call(SetModeParams params) =>
      _repo.setSelectionMode(roomId: params.roomId, mode: params.mode);
}

class SetModeParams {
  const SetModeParams({required this.roomId, required this.mode});
  final String roomId;
  final SelectionMode mode;
}

class GetInviteLink extends UseCase<String, String> {
  GetInviteLink(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<String>> call(String roomId) => _repo.getInviteLink(roomId);
}

class GetRoomHistory extends UseCase<List<Room>, NoParams> {
  GetRoomHistory(this._repo);
  final RoomRepository _repo;

  @override
  Future<Result<List<Room>>> call(NoParams params) => _repo.getHistory();
}
