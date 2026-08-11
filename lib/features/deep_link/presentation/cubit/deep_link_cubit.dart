import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/deep_link_repository.dart';

class DeepLinkState extends Equatable {
  const DeepLinkState({this.pendingRoomId});

  final String? pendingRoomId;

  @override
  List<Object?> get props => [pendingRoomId];
}

class DeepLinkCubit extends Cubit<DeepLinkState> {
  DeepLinkCubit(this._repository) : super(const DeepLinkState()) {
    _sub = _repository.watchPendingInvite().listen((id) {
      emit(DeepLinkState(pendingRoomId: id));
    });
  }

  final DeepLinkRepository _repository;
  late final StreamSubscription<String?> _sub;

  Future<void> startListening() => _repository.startListening();

  Future<void> handleUri(Uri uri) => _repository.handleUri(uri);

  Future<void> setPending(String? roomId) =>
      _repository.setPendingRoomId(roomId);

  String? consumePending() {
    final id = _repository.getPendingRoomId();
    _repository.setPendingRoomId(null);
    return id;
  }

  Future<String> createInvite(String roomId, {String? inviterId}) =>
      _repository.createInviteLink(roomId: roomId, inviterId: inviterId);

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
