import 'package:equatable/equatable.dart';

enum RaceStatus { idle, countdown, racing, finished }

class RaceState extends Equatable {
  const RaceState({
    required this.roomId,
    required this.suggestionIds,
    required this.status,
    this.winnerId,
    this.isTiebreaker = false,
  });

  final String roomId;
  final List<String> suggestionIds;
  final RaceStatus status;
  final String? winnerId;

  /// True when the race exists only to break a tie coming out of voting.
  final bool isTiebreaker;

  RaceState copyWith({
    RaceStatus? status,
    String? winnerId,
    List<String>? suggestionIds,
    bool? isTiebreaker,
  }) {
    return RaceState(
      roomId: roomId,
      suggestionIds: suggestionIds ?? this.suggestionIds,
      status: status ?? this.status,
      winnerId: winnerId ?? this.winnerId,
      isTiebreaker: isTiebreaker ?? this.isTiebreaker,
    );
  }

  @override
  List<Object?> get props =>
      [roomId, suggestionIds, status, winnerId, isTiebreaker];
}
