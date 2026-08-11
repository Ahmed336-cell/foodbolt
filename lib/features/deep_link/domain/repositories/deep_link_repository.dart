abstract class DeepLinkRepository {
  /// Start listening for OS / app_links invite URLs.
  Future<void> startListening();

  Future<void> setPendingRoomId(String? roomId);

  String? getPendingRoomId();

  Stream<String?> watchPendingInvite();

  Future<String> createInviteLink({required String roomId, String? inviterId});

  /// Handle a URI manually (tests / in-app `/join/:code` route).
  Future<void> handleUri(Uri uri);
}
