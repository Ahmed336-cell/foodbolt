import 'package:equatable/equatable.dart';

class Vote extends Equatable {
  const Vote({
    required this.roomId,
    required this.userId,
    required this.suggestionId,
  });

  final String roomId;
  final String userId;
  final String suggestionId;

  @override
  List<Object?> get props => [roomId, userId, suggestionId];
}

class VotingSnapshot extends Equatable {
  const VotingSnapshot({
    required this.roomId,
    required this.votes,
    required this.counts,
    this.mySuggestionId,
    this.winnerId,
    this.revealed = false,
    this.tiedSuggestionIds = const [],
  });

  final String roomId;
  final List<Vote> votes;
  final Map<String, int> counts;
  final String? mySuggestionId;
  final String? winnerId;
  final bool revealed;
  final List<String> tiedSuggestionIds;

  bool get isTie => tiedSuggestionIds.length > 1;

  @override
  List<Object?> get props =>
      [roomId, votes, counts, mySuggestionId, winnerId, revealed, tiedSuggestionIds];
}

/// Result of the host revealing the vote: either a clear winner, or a set of
/// tied restaurants that must settle it with a race.
class VoteRevealOutcome extends Equatable {
  const VoteRevealOutcome({this.winnerId, this.tiedSuggestionIds = const []});

  final String? winnerId;
  final List<String> tiedSuggestionIds;

  bool get isTie => winnerId == null && tiedSuggestionIds.length > 1;

  @override
  List<Object?> get props => [winnerId, tiedSuggestionIds];
}
