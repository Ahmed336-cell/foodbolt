import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/deep_link/app_deep_link_listener.dart';
import '../../../../core/deep_link/invite_links.dart';
import '../../domain/repositories/deep_link_repository.dart';

/// Supabase-backed deep links: OS URIs → resolve room via RPC → pending join.
class DeepLinkSupabaseRepository implements DeepLinkRepository {
  DeepLinkSupabaseRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final _controller = StreamController<String?>.broadcast();
  String? _pendingRoomId;
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
    var resolved = roomId?.trim();
    if (resolved != null &&
        resolved.isNotEmpty &&
        !InviteLinks.looksLikeUuid(resolved)) {
      resolved = await _resolveCodeToId(resolved) ?? resolved.toUpperCase();
    }
    _pendingRoomId = resolved;
    _controller.add(resolved);
  }

  Future<String?> _resolveCodeToId(String code) async {
    try {
      final rows = await _client.rpc(
        'get_room_by_code',
        params: {'p_code': code},
      );
      if (rows is List && rows.isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first as Map);
        return row['id'] as String?;
      }
    } catch (_) {
      // Keep code; RoomSessionScreen can still joinWithCode.
    }
    return null;
  }

  @override
  String? getPendingRoomId() => _pendingRoomId;

  @override
  Stream<String?> watchPendingInvite() async* {
    yield _pendingRoomId;
    yield* _controller.stream;
  }

  @override
  Future<String> createInviteLink({
    required String roomId,
    String? inviterId,
  }) async {
    try {
      final row = await _client
          .from('rooms')
          .select('invite_url, code')
          .eq('id', roomId)
          .maybeSingle();

      final existing = row?['invite_url'] as String?;
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }

      final code = (row?['code'] as String?) ?? roomId;
      final url = InviteLinks.forToken(code);
      await _client.from('rooms').update({'invite_url': url}).eq('id', roomId);
      return url;
    } catch (_) {
      return InviteLinks.forToken(roomId);
    }
  }
}
