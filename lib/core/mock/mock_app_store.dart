import 'dart:async';
import 'dart:math';

import 'package:uuid/uuid.dart';

import '../../core/error/failures.dart';
import '../../core/phase/room_phase.dart';
import '../../core/room/room_code.dart';
import '../../core/usecase/usecase.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/cost_sharing/domain/entities/cost_share.dart';
import '../../features/orders/domain/entities/user_order.dart';
import '../../features/payment_summary/domain/entities/payment_record.dart';
import '../../features/race/domain/entities/race_state.dart';
import '../../features/receipt/domain/entities/receipt.dart';
import '../../features/room/domain/entities/room.dart';
import '../../features/suggestions/domain/entities/restaurant_suggestion.dart';
import '../../features/voting/domain/entities/vote.dart';

/// In-memory source of truth for mock-first MVP.
class MockAppStore {
  MockAppStore() {
    _seedDemoUsers();
  }

  final _uuid = const Uuid();
  final _rand = Random();

  AppUser? currentUser;
  final Map<String, AppUser> users = {};
  final Map<String, Room> rooms = {};
  final Map<String, List<RoomMember>> members = {};
  final Map<String, List<RestaurantSuggestion>> suggestions = {};
  final Map<String, List<Vote>> votes = {};
  final Map<String, bool> voteRevealed = {};

  /// Suggestions tied on votes and waiting for a tiebreaker race.
  final Map<String, List<String>> tiebreakCandidates = {};
  final Map<String, RaceState> races = {};
  final Map<String, List<UserOrder>> orders = {};
  final Map<String, Receipt> receipts = {};
  final Map<String, CostShareDraft> costShares = {};
  final Map<String, List<PaymentRecord>> payments = {};
  String? pendingInviteRoomId;

  final _authController = StreamController<AppUser?>.broadcast();
  final _roomControllers = <String, StreamController<Room>>{};
  final _membersControllers = <String, StreamController<List<RoomMember>>>{};
  final _suggestionControllers =
      <String, StreamController<List<RestaurantSuggestion>>>{};
  final _voteControllers = <String, StreamController<VotingSnapshot>>{};
  final _raceControllers = <String, StreamController<RaceState>>{};
  final _orderControllers = <String, StreamController<List<UserOrder>>>{};
  final _receiptControllers = <String, StreamController<Receipt>>{};
  final _costControllers = <String, StreamController<CostShareDraft>>{};
  final _paymentControllers = <String, StreamController<List<PaymentRecord>>>{};

  static const avatarColors = [
    0xFFE85D04,
    0xFF2A9D8F,
    0xFFE76F51,
    0xFF264653,
    0xFFF4A261,
    0xFF9B5DE5,
  ];

  void _seedDemoUsers() {
    // Empty — users created on login/guest.
  }

  Stream<AppUser?> get authStream => _authController.stream;

  StreamController<T> _ctrl<T>(
    Map<String, StreamController<T>> map,
    String key,
  ) {
    return map.putIfAbsent(key, () => StreamController<T>.broadcast());
  }

  void setCurrentUser(AppUser? user) {
    currentUser = user;
    if (user != null) users[user.id] = user;
    _authController.add(user);
  }

  Result<AppUser> requireUser() {
    final user = currentUser;
    if (user == null) return const Failed(AuthFailure('Not signed in.'));
    return Success(user);
  }

  Result<Room> requireRoom(String roomId) {
    final room = rooms[roomId];
    if (room == null) return const Failed(NotFoundFailure('Room not found.'));
    return Success(room);
  }

  Result<void> requireHost(String roomId, String userId) {
    final room = rooms[roomId];
    if (room == null) return const Failed(NotFoundFailure('Room not found.'));
    if (room.hostId != userId) {
      return const Failed(PermissionFailure());
    }
    return const Success(null);
  }

  Result<void> requireMember(String roomId, String userId) {
    final list = members[roomId] ?? [];
    if (!list.any((m) => m.userId == userId)) {
      return const Failed(PermissionFailure('Join the room first.'));
    }
    return const Success(null);
  }

  String generateCode() {
    const chars = RoomCode.alphabet;
    return List.generate(
      RoomCode.length,
      (_) => chars[_rand.nextInt(chars.length)],
    ).join();
  }

  String funRoomName() {
    const adjectives = ['Friday', 'Hungry', 'Bolt', 'Midnight', 'Spicy', 'Cozy'];
    const nouns = ['Lunch', 'Feast', 'Raid', 'Squad', 'Night', 'Craving'];
    return '${adjectives[_rand.nextInt(adjectives.length)]} ${nouns[_rand.nextInt(nouns.length)]}';
  }

  void emitRoom(Room room) {
    rooms[room.id] = room;
    _ctrl(_roomControllers, room.id).add(room);
  }

  void emitMembers(String roomId) {
    _ctrl(_membersControllers, roomId).add(List.unmodifiable(members[roomId] ?? []));
  }

  void emitSuggestions(String roomId) {
    final list = List<RestaurantSuggestion>.from(suggestions[roomId] ?? []);
    final counts = <String, int>{};
    for (final v in votes[roomId] ?? []) {
      counts[v.suggestionId] = (counts[v.suggestionId] ?? 0) + 1;
    }
    final withCounts = list
        .map((s) => s.copyWith(voteCount: counts[s.id] ?? 0))
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    suggestions[roomId] = withCounts;
    _ctrl(_suggestionControllers, roomId).add(List.unmodifiable(withCounts));
  }

  VotingSnapshot buildVotingSnapshot(String roomId, {String? viewerId}) {
    final voteList = votes[roomId] ?? [];
    final counts = <String, int>{};
    for (final v in voteList) {
      counts[v.suggestionId] = (counts[v.suggestionId] ?? 0) + 1;
    }
    String? mine;
    if (viewerId != null) {
      mine = voteList
          .where((v) => v.userId == viewerId)
          .map((v) => v.suggestionId)
          .firstOrNull;
    }
    final room = rooms[roomId];
    return VotingSnapshot(
      roomId: roomId,
      votes: List.unmodifiable(voteList),
      counts: counts,
      mySuggestionId: mine,
      winnerId: room?.winnerSuggestionId,
      revealed: voteRevealed[roomId] ?? false,
      tiedSuggestionIds: List.unmodifiable(tiebreakCandidates[roomId] ?? const []),
    );
  }

  void emitVotes(String roomId) {
    _ctrl(_voteControllers, roomId).add(buildVotingSnapshot(roomId, viewerId: currentUser?.id));
  }

  void emitRace(RaceState state) {
    races[state.roomId] = state;
    _ctrl(_raceControllers, state.roomId).add(state);
  }

  void emitOrders(String roomId) {
    _ctrl(_orderControllers, roomId)
        .add(List.unmodifiable(orders[roomId] ?? []));
  }

  void emitReceipt(Receipt receipt) {
    receipts[receipt.roomId] = receipt;
    _ctrl(_receiptControllers, receipt.roomId).add(receipt);
  }

  void emitCost(CostShareDraft draft) {
    costShares[draft.roomId] = draft;
    _ctrl(_costControllers, draft.roomId).add(draft);
  }

  void emitPayments(String roomId) {
    _ctrl(_paymentControllers, roomId)
        .add(List.unmodifiable(payments[roomId] ?? []));
  }

  Stream<Room> watchRoom(String roomId) async* {
    final room = rooms[roomId];
    if (room != null) yield room;
    yield* _ctrl(_roomControllers, roomId).stream;
  }

  Stream<List<RoomMember>> watchMembers(String roomId) async* {
    yield List.unmodifiable(members[roomId] ?? []);
    yield* _ctrl(_membersControllers, roomId).stream;
  }

  Stream<List<RestaurantSuggestion>> watchSuggestions(String roomId) async* {
    emitSuggestions(roomId);
    yield List.unmodifiable(suggestions[roomId] ?? []);
    yield* _ctrl(_suggestionControllers, roomId).stream;
  }

  Stream<VotingSnapshot> watchVotes(String roomId) async* {
    yield buildVotingSnapshot(roomId, viewerId: currentUser?.id);
    yield* _ctrl(_voteControllers, roomId).stream;
  }

  Stream<RaceState> watchRace(String roomId) async* {
    final race = races[roomId];
    if (race != null) yield race;
    yield* _ctrl(_raceControllers, roomId).stream;
  }

  Stream<List<UserOrder>> watchOrders(String roomId) async* {
    yield List.unmodifiable(orders[roomId] ?? []);
    yield* _ctrl(_orderControllers, roomId).stream;
  }

  Stream<Receipt> watchReceipt(String roomId) async* {
    final receipt = receipts[roomId] ??
        Receipt(roomId: roomId, status: ReceiptStatus.none);
    yield receipt;
    yield* _ctrl(_receiptControllers, roomId).stream;
  }

  Stream<CostShareDraft> watchCost(String roomId) async* {
    final draft = costShares[roomId];
    if (draft != null) yield draft;
    yield* _ctrl(_costControllers, roomId).stream;
  }

  Stream<List<PaymentRecord>> watchPayments(String roomId) async* {
    yield List.unmodifiable(payments[roomId] ?? []);
    yield* _ctrl(_paymentControllers, roomId).stream;
  }

  String newId() => _uuid.v4();

  List<Room> historyForUser(String userId) {
    final joined = rooms.values.where((r) {
      final mems = members[r.id] ?? [];
      return mems.any((m) => m.userId == userId) &&
          r.phase == RoomPhase.completed;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return joined;
  }

  CostShareDraft recalculateCost({
    required String roomId,
    required double receiptTotal,
    required AdditionalCosts extras,
    Map<String, double>? adjustments,
  }) {
    final orderList = (orders[roomId] ?? []).where((o) => o.submitted).toList();
    final expected = orderList.fold<double>(0, (s, o) => s + o.subtotal);
    final memberCount = orderList.isEmpty ? 1 : orderList.length;
    final extrasPer = extras.netExtras / memberCount;
    final diff = receiptTotal - (expected + extras.netExtras);
    final diffPer = diff / memberCount;

    final shares = orderList.map((o) {
      final adj = adjustments?[o.userId] ?? 0;
      final finalAmount = o.subtotal + extrasPer + diffPer + adj;
      return ParticipantShare(
        userId: o.userId,
        displayName: o.displayName,
        orderSubtotal: o.subtotal,
        extrasShare: extrasPer + diffPer,
        adjustment: adj,
        finalAmount: double.parse(finalAmount.toStringAsFixed(2)),
      );
    }).toList();

    // Fix rounding so shares sum to receiptTotal
    if (shares.isNotEmpty) {
      final sum = shares.fold<double>(0, (s, p) => s + p.finalAmount);
      final delta = double.parse((receiptTotal - sum).toStringAsFixed(2));
      if (delta != 0) {
        final last = shares.last;
        shares[shares.length - 1] = ParticipantShare(
          userId: last.userId,
          displayName: last.displayName,
          orderSubtotal: last.orderSubtotal,
          extrasShare: last.extrasShare,
          adjustment: last.adjustment + delta,
          finalAmount: double.parse((last.finalAmount + delta).toStringAsFixed(2)),
        );
      }
    }

    return CostShareDraft(
      roomId: roomId,
      receiptTotal: receiptTotal,
      expectedOrdersTotal: expected,
      additionalCosts: extras,
      shares: shares,
    );
  }
}
