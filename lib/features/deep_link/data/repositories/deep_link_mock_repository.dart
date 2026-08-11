import 'dart:async';

import '../../../../core/deep_link/app_deep_link_listener.dart';
import '../../../../core/deep_link/invite_links.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../domain/repositories/deep_link_repository.dart';

class DeepLinkMockRepository implements DeepLinkRepository {
  DeepLinkMockRepository(this._store);

  final MockAppStore _store;
  final _controller = StreamController<String?>.broadcast();
  late final AppDeepLinkListener _listener =
      AppDeepLinkListener(_onInviteToken);

  @override
  Future<void> startListening() => _listener.start();

  @override
  Future<void> handleUri(Uri uri) => _listener.handleUri(uri);

  Future<void> _onInviteToken(String token) async {
    await setPendingRoomId(token);
  }

  @override
  Future<void> setPendingRoomId(String? roomId) async {
    _store.pendingInviteRoomId = roomId;
    _controller.add(roomId);
  }

  @override
  String? getPendingRoomId() => _store.pendingInviteRoomId;

  @override
  Stream<String?> watchPendingInvite() async* {
    yield _store.pendingInviteRoomId;
    yield* _controller.stream;
  }

  @override
  Future<String> createInviteLink({
    required String roomId,
    String? inviterId,
  }) async {
    final room = _store.rooms[roomId];
    return InviteLinks.forToken(room?.code ?? roomId);
  }
}
