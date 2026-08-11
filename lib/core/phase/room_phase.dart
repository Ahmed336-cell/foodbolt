enum RoomPhase {
  lobby,
  suggestions,
  voting,
  draw,
  race,
  restaurantSelected,
  ordering,
  ordersLocked,
  receipt,
  costReview,
  paymentSummary,
  completed;

  String get label => switch (this) {
        RoomPhase.lobby => 'Lobby',
        RoomPhase.suggestions => 'Suggestions',
        RoomPhase.voting => 'Voting',
        RoomPhase.draw => 'Draw',
        RoomPhase.race => 'Race',
        RoomPhase.restaurantSelected => 'Restaurant Selected',
        RoomPhase.ordering => 'Ordering',
        RoomPhase.ordersLocked => 'Orders Locked',
        RoomPhase.receipt => 'Receipt',
        RoomPhase.costReview => 'Cost Review',
        RoomPhase.paymentSummary => 'Payment',
        RoomPhase.completed => 'Completed',
      };

  String get routeSegment => switch (this) {
        RoomPhase.lobby => 'lobby',
        RoomPhase.suggestions => 'suggestions',
        RoomPhase.voting => 'voting',
        RoomPhase.draw => 'draw',
        RoomPhase.race => 'race',
        RoomPhase.restaurantSelected => 'selected',
        RoomPhase.ordering => 'ordering',
        RoomPhase.ordersLocked => 'group-orders',
        RoomPhase.receipt => 'receipt',
        RoomPhase.costReview => 'cost-review',
        RoomPhase.paymentSummary => 'payment',
        RoomPhase.completed => 'summary',
      };

  static RoomPhase fromName(String name) =>
      RoomPhase.values.firstWhere((e) => e.name == name, orElse: () => RoomPhase.lobby);
}

/// How the room picks a restaurant after suggestions.
enum SelectionMode {
  /// Add restaurants → race immediately.
  raceDirect,

  /// Add restaurants → vote; if top votes tie → race those only.
  voteWithTieRace,

  /// Add restaurants → vote only (host picks if votes tie).
  voteOnly;

  bool get goesToVote =>
      this == SelectionMode.voteWithTieRace || this == SelectionMode.voteOnly;

  bool get goesToRaceDirect => this == SelectionMode.raceDirect;

  bool get racesOnTie => this == SelectionMode.voteWithTieRace;

  String get label => switch (this) {
        SelectionMode.raceDirect => 'Suggest & Race',
        SelectionMode.voteWithTieRace => 'Vote (race on draw)',
        SelectionMode.voteOnly => 'Vote only',
      };
}
