import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// True when device has usable internet (not just Wi‑Fi/cellular on).
class ConnectivityGuard {
  ConnectivityGuard._();

  static final Connectivity _connectivity = Connectivity();

  static Future<bool> hasInternet() async {
    if (kIsWeb) return true;

    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      if (results.isEmpty ||
          results.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
    } catch (_) {
      // Fall through to DNS probe — some emulators lie about connectivity.
    }

    return _canResolveHost();
  }

  static Future<bool> _canResolveHost() async {
    for (final host in const ['one.one.one.one', 'dns.google', '8.8.8.8']) {
      try {
        final lookup = await InternetAddress.lookup(host)
            .timeout(const Duration(seconds: 2));
        if (lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // try next host
      }
    }
    return false;
  }

  static Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
