import '../config/env.dart';
import '../constants/app_constants.dart';

/// Builds and parses FoodRush room invite deep links.
///
/// Supported forms:
/// - `foodrush://join/ABC123`
/// - `https://foodrush.app/join/ABC123`
/// - `...?code=ABC123` / `...?roomId=<uuid>`
class InviteLinks {
  InviteLinks._();

  static String get base {
    final fromEnv = AppEnv.inviteBaseUrl;
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/+$'), '');
    return AppConstants.inviteBase;
  }

  /// Shareable invite URL for a room code (preferred) or id.
  static String forToken(String codeOrId) {
    final token = codeOrId.trim();
    final b = base;
    if (b.contains('://')) {
      // Custom scheme: foodrush://join/{token}
      if (RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(b) &&
          !b.startsWith('http')) {
        return '$b/${Uri.encodeComponent(token)}';
      }
      return '$b/${Uri.encodeComponent(token)}';
    }
    return '${AppConstants.inviteScheme}://join/${Uri.encodeComponent(token)}';
  }

  /// Extract room code or id from an incoming URI, or null if not an invite.
  static String? parseToken(Uri uri) {
    final qp = uri.queryParameters;
    final fromQuery = qp['code'] ?? qp['room'] ?? qp['roomId'] ?? qp['id'];
    if (fromQuery != null && fromQuery.trim().isNotEmpty) {
      return fromQuery.trim();
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // foodrush://join/CODE  → host=join, path=/CODE
    if (uri.scheme == AppConstants.inviteScheme || uri.scheme == 'foodbolt') {
      if (uri.host.toLowerCase() == 'join' && segments.isNotEmpty) {
        return Uri.decodeComponent(segments.first);
      }
      if (segments.length >= 2 && segments[0].toLowerCase() == 'join') {
        return Uri.decodeComponent(segments[1]);
      }
      if (segments.isNotEmpty) {
        return Uri.decodeComponent(segments.last);
      }
    }

    // https://foodbolt.app/join/CODE
    final joinIdx = segments.indexWhere((s) => s.toLowerCase() == 'join');
    if (joinIdx >= 0 && joinIdx + 1 < segments.length) {
      return Uri.decodeComponent(segments[joinIdx + 1]);
    }

    return null;
  }

  static bool looksLikeUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}
