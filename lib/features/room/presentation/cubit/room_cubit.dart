import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/phase/room_phase.dart';
import '../../domain/entities/room.dart';
import '../../domain/repositories/room_repository.dart';
import '../../domain/usecases/room_usecases.dart';

class RoomState extends Equatable {
  const RoomState({
    this.room,
    this.members = const [],
    this.loading = false,
    this.error,
    this.joinToast,
  });

  final Room? room;
  final List<RoomMember> members;
  final bool loading;
  final String? error;
  final String? joinToast;

  bool isHost(String? userId) =>
      userId != null && room != null && room!.hostId == userId;

  RoomState copyWith({
    Room? room,
    List<RoomMember>? members,
    bool? loading,
    String? error,
    String? joinToast,
    bool clearError = false,
    bool clearToast = false,
  }) {
    return RoomState(
      room: room ?? this.room,
      members: members ?? this.members,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      joinToast: clearToast ? null : (joinToast ?? this.joinToast),
    );
  }

  @override
  List<Object?> get props => [room, members, loading, error, joinToast];
}

class RoomCubit extends Cubit<RoomState> {
  RoomCubit({
    required RoomRepository roomRepository,
    required CreateRoom createRoom,
    required JoinRoom joinRoom,
    required JoinRoomById joinRoomById,
    required SetRoomPhase setRoomPhase,
    required SetRoomSelectionMode setRoomSelectionMode,
    required GetInviteLink getInviteLink,
  })  : _roomRepository = roomRepository,
        _createRoom = createRoom,
        _joinRoom = joinRoom,
        _joinRoomById = joinRoomById,
        _setRoomPhase = setRoomPhase,
        _setRoomSelectionMode = setRoomSelectionMode,
        _getInviteLink = getInviteLink,
        super(const RoomState());

  final RoomRepository _roomRepository;
  final CreateRoom _createRoom;
  final JoinRoom _joinRoom;
  final JoinRoomById _joinRoomById;
  final SetRoomPhase _setRoomPhase;
  final SetRoomSelectionMode _setRoomSelectionMode;
  final GetInviteLink _getInviteLink;

  StreamSubscription<Room>? _roomSub;
  StreamSubscription<List<RoomMember>>? _membersSub;
  List<String> _knownMemberIds = [];

  Future<Room?> create({
    required String name,
    required SelectionMode mode,
    RoomSettings settings = const RoomSettings(),
  }) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _createRoom(
      CreateRoomParams(name: name, selectionMode: mode, settings: settings),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return null;
      },
      (room) {
        watch(room.id);
        emit(state.copyWith(room: room, loading: false));
        return room;
      },
    );
  }

  Future<Room?> joinWithCode(String code) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _joinRoom(code);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return null;
      },
      (room) {
        watch(room.id);
        emit(state.copyWith(room: room, loading: false));
        return room;
      },
    );
  }

  Future<Room?> joinWithId(String roomId) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _joinRoomById(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return null;
      },
      (room) {
        watch(room.id);
        emit(state.copyWith(room: room, loading: false));
        return room;
      },
    );
  }

  void watch(String roomId) {
    _roomSub?.cancel();
    _membersSub?.cancel();
    _roomSub = _roomRepository.watchRoom(roomId).listen((room) {
      emit(state.copyWith(room: room));
    });
    _membersSub = _roomRepository.watchMembers(roomId).listen((members) {
      final newOnes = members
          .where((m) => !_knownMemberIds.contains(m.userId))
          .toList();
      _knownMemberIds = members.map((m) => m.userId).toList();
      String? toast;
      if (newOnes.isNotEmpty && state.members.isNotEmpty) {
        toast = '${newOnes.last.displayName} joined the room';
      }
      emit(state.copyWith(members: members, joinToast: toast));
    });
  }

  Future<bool> startGame() async {
    final room = state.room;
    if (room == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _setRoomPhase(
      SetPhaseParams(roomId: room.id, phase: RoomPhase.suggestions),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<bool> updateSelectionMode(SelectionMode mode) async {
    final room = state.room;
    if (room == null) return false;
    final result = await _setRoomSelectionMode(
      SetModeParams(roomId: room.id, mode: mode),
    );
    return result.fold((f) {
      emit(state.copyWith(error: f.message));
      return false;
    }, (_) => true);
  }

  Future<bool> advancePhase(RoomPhase phase) async {
    final room = state.room;
    if (room == null) return false;
    final result =
        await _setRoomPhase(SetPhaseParams(roomId: room.id, phase: phase));
    return result.fold((f) {
      emit(state.copyWith(error: f.message));
      return false;
    }, (_) => true);
  }

  Future<String?> inviteLink() async {
    final room = state.room;
    if (room == null) return null;
    final result = await _getInviteLink(room.id);
    return result.dataOrNull;
  }

  void clearToast() => emit(state.copyWith(clearToast: true));

  @override
  Future<void> close() async {
    await _roomSub?.cancel();
    await _membersSub?.cancel();
    return super.close();
  }
}
