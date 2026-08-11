import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import 'invite_links.dart';

/// Listens for OS deep links and forwards invite tokens.
class AppDeepLinkListener {
  AppDeepLinkListener(this._onToken);

  final Future<void> Function(String token) _onToken;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handle(initial);
      }
    } catch (e) {
      debugPrint('DeepLink: initial link failed: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      (uri) => _handle(uri),
      onError: (Object e) => debugPrint('DeepLink: stream error: $e'),
    );
  }

  Future<void> handleUri(Uri uri) => _handle(uri);

  Future<void> _handle(Uri uri) async {
    debugPrint('DeepLink: received $uri');
    final token = InviteLinks.parseToken(uri);
    if (token == null || token.isEmpty) {
      debugPrint('DeepLink: no invite token in $uri');
      return;
    }
    await _onToken(token);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
