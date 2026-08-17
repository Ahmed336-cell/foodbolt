import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../error/failures.dart';
import '../phase/room_phase.dart';
import '../../features/race/domain/entities/race_state.dart';
import '../../features/receipt/domain/entities/receipt.dart';

/// Shared Postgres ↔ domain mappers for Supabase repositories.
class SupabaseMappers {
  SupabaseMappers._();

  static RoomPhase roomPhaseFromDb(String? value) {
    return switch (value) {
      'lobby' => RoomPhase.lobby,
      'suggestions' => RoomPhase.suggestions,
      'voting' => RoomPhase.voting,
      'draw' => RoomPhase.draw,
      'race' => RoomPhase.race,
      'restaurant_selected' => RoomPhase.restaurantSelected,
      'ordering' => RoomPhase.ordering,
      'orders_locked' => RoomPhase.ordersLocked,
      'receipt' => RoomPhase.receipt,
      'cost_review' => RoomPhase.costReview,
      'payment_summary' => RoomPhase.paymentSummary,
      'completed' => RoomPhase.completed,
      _ => RoomPhase.lobby,
    };
  }

  static String roomPhaseToDb(RoomPhase phase) {
    return switch (phase) {
      RoomPhase.lobby => 'lobby',
      RoomPhase.suggestions => 'suggestions',
      RoomPhase.voting => 'voting',
      RoomPhase.draw => 'draw',
      RoomPhase.race => 'race',
      RoomPhase.restaurantSelected => 'restaurant_selected',
      RoomPhase.ordering => 'ordering',
      RoomPhase.ordersLocked => 'orders_locked',
      RoomPhase.receipt => 'receipt',
      RoomPhase.costReview => 'cost_review',
      RoomPhase.paymentSummary => 'payment_summary',
      RoomPhase.completed => 'completed',
    };
  }

  static SelectionMode selectionModeFromDb(String? value) {
    return switch (value) {
      'race_direct' => SelectionMode.raceDirect,
      'vote_with_tie_race' => SelectionMode.voteWithTieRace,
      'vote_only' => SelectionMode.voteOnly,
      _ => SelectionMode.voteWithTieRace,
    };
  }

  static String selectionModeToDb(SelectionMode mode) {
    return switch (mode) {
      SelectionMode.raceDirect => 'race_direct',
      SelectionMode.voteWithTieRace => 'vote_with_tie_race',
      SelectionMode.voteOnly => 'vote_only',
    };
  }

  static RaceStatus raceStatusFromDb(String? value) {
    return switch (value) {
      'idle' => RaceStatus.idle,
      'countdown' => RaceStatus.countdown,
      'racing' => RaceStatus.racing,
      'finished' => RaceStatus.finished,
      _ => RaceStatus.idle,
    };
  }

  static String raceStatusToDb(RaceStatus status) {
    return switch (status) {
      RaceStatus.idle => 'idle',
      RaceStatus.countdown => 'countdown',
      RaceStatus.racing => 'racing',
      RaceStatus.finished => 'finished',
    };
  }

  static ReceiptStatus receiptStatusFromDb(String? value) {
    return switch (value) {
      'uploaded' => ReceiptStatus.uploaded,
      'skipped' => ReceiptStatus.skipped,
      _ => ReceiptStatus.none,
    };
  }

  static String receiptStatusToDb(ReceiptStatus status) {
    return switch (status) {
      ReceiptStatus.none => 'none',
      ReceiptStatus.uploaded => 'uploaded',
      ReceiptStatus.skipped => 'skipped',
    };
  }

  static double asDouble(dynamic value, [double fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static int asInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static List<String> asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).toList();
  }

  static Failure mapError(Object error, [StackTrace? stackTrace]) {
    if (error is AuthException) {
      final code = error.code?.toLowerCase() ?? '';
      final message = error.message.toLowerCase();
      if (code == 'email_not_confirmed' ||
          message.contains('email not confirmed') ||
          message.contains('email_not_confirmed')) {
        return const AuthFailure(
          'Activate your account first before you can join.',
        );
      }
      if (_looksTechnical(error.message)) {
        return const AuthFailure();
      }
      return AuthFailure(error.message);
    }
    if (error is StorageException) {
      return _fromParts(code: error.statusCode, message: error.message);
    }
    if (error is FunctionException) {
      return _fromParts(
        code: '${error.status}',
        message: error.details?.toString() ?? error.reasonPhrase ?? '',
        details: error.details,
      );
    }
    if (error is PostgrestException) {
      return _fromParts(
        code: error.code,
        message: error.message,
        details: error.details,
      );
    }
    return _fromParts(message: error.toString());
  }

  static Failure _fromParts({
    String? code,
    required String message,
    Object? details,
  }) {
    var resolvedCode = code;
    var resolvedMessage = message;
    var resolvedDetails = details;

    final json = _tryDecodeMap(message) ?? _tryDecodeMap(details);
    if (json != null) {
      resolvedCode = json['code']?.toString() ?? resolvedCode;
      resolvedMessage = json['message']?.toString() ?? resolvedMessage;
      resolvedDetails = json['details'] ?? resolvedDetails;
    }

    final haystack =
        '${resolvedCode ?? ''} $resolvedMessage ${resolvedDetails ?? ''}'
            .toLowerCase();

    if (resolvedCode == 'PGRST116' ||
        haystack.contains('pgrst116') ||
        haystack.contains('0 rows') ||
        haystack.contains('cannot coerce')) {
      return const NotFoundFailure();
    }
    if (resolvedCode == '42501' ||
        haystack.contains('permission') ||
        haystack.contains('row-level security')) {
      return const PermissionFailure();
    }
    if (haystack.contains('not authenticated')) {
      return const AuthFailure('Not signed in.');
    }
    if (resolvedMessage == 'Restaurant not found.' ||
        haystack.contains('restaurant not found')) {
      return const NotFoundFailure('Restaurant not found.');
    }
    if (haystack.contains('could not be deleted')) {
      return const AuthFailure('Account could not be deleted.');
    }
    if (resolvedCode == '23514' ||
        resolvedCode == '23502' ||
        resolvedCode == '22P02' ||
        resolvedCode == '23503' ||
        resolvedCode == '23505') {
      return const ServerFailure();
    }
    if (_looksTechnical(resolvedMessage) || _looksTechnical(haystack)) {
      return const ServerFailure();
    }
    if (resolvedMessage.trim().isEmpty) {
      return const ServerFailure();
    }
    return ServerFailure(resolvedMessage);
  }

  static Map<String, dynamic>? _tryDecodeMap(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is! String) return null;
    final trimmed = value.trim();
    if (!trimmed.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  static bool _looksTechnical(String value) {
    final t = value.trim().toLowerCase();
    if (t.isEmpty) return false;
    return t.startsWith('{') ||
        t.contains('pgrst') ||
        t.contains('postgrestexception') ||
        t.contains('sqlstate') ||
        t.contains('cannot coerce') ||
        t.contains('violates') ||
        t.contains('json object requested');
  }

  static String? requireUserId(SupabaseClient client) =>
      client.auth.currentUser?.id;
}
