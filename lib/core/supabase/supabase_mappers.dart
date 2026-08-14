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
      return AuthFailure(error.message);
    }
    if (error is StorageException) {
      return ServerFailure(error.message);
    }
    if (error is PostgrestException) {
      final code = error.code;
      final message = error.message;
      if (code == 'PGRST116') {
        return NotFoundFailure(message.isEmpty ? 'Not found.' : message);
      }
      if (code == '42501' || message.toLowerCase().contains('permission')) {
        return PermissionFailure(message);
      }
      if (code == '23514' || code == '23502' || code == '22P02') {
        return ValidationFailure(message);
      }
      // Prefer real DB message (FK / raise exception) over generic "Not found."
      if (code == '23503') {
        return ServerFailure(message);
      }
      if (message.toLowerCase().contains('not authenticated') ||
          message.toLowerCase().contains('could not be deleted')) {
        return AuthFailure(message);
      }
      return ServerFailure(message);
    }
    return ServerFailure(error.toString());
  }

  static String? requireUserId(SupabaseClient client) =>
      client.auth.currentUser?.id;
}
