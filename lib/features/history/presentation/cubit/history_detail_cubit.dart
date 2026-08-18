import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cost_sharing/domain/entities/cost_share.dart';
import '../../../cost_sharing/domain/repositories/cost_sharing_repository.dart';
import '../../../orders/domain/entities/user_order.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/domain/repositories/receipt_repository.dart';
import '../../../room/domain/entities/room.dart';
import '../../../room/domain/usecases/room_usecases.dart';
import '../../../suggestions/domain/repositories/suggestion_repository.dart';

class HistoryDetailState extends Equatable {
  const HistoryDetailState({
    this.loading = false,
    this.error,
    this.room,
    this.restaurantName,
    this.orders = const [],
    this.receipt,
    this.costShare,
  });

  final bool loading;
  final String? error;
  final Room? room;
  final String? restaurantName;
  final List<UserOrder> orders;
  final Receipt? receipt;
  final CostShareDraft? costShare;

  @override
  List<Object?> get props =>
      [loading, error, room, restaurantName, orders, receipt, costShare];
}

class HistoryDetailCubit extends Cubit<HistoryDetailState> {
  HistoryDetailCubit({
    required GetRoom getRoom,
    required OrderRepository orderRepository,
    required ReceiptRepository receiptRepository,
    required CostSharingRepository costSharingRepository,
    required SuggestionRepository suggestionRepository,
  })  : _getRoom = getRoom,
        _orders = orderRepository,
        _receipts = receiptRepository,
        _costs = costSharingRepository,
        _suggestions = suggestionRepository,
        super(const HistoryDetailState());

  final GetRoom _getRoom;
  final OrderRepository _orders;
  final ReceiptRepository _receipts;
  final CostSharingRepository _costs;
  final SuggestionRepository _suggestions;

  Future<void> load(String roomId) async {
    emit(const HistoryDetailState(loading: true));

    final roomResult = await _getRoom(roomId);
    final room = roomResult.dataOrNull;
    if (room == null) {
      emit(HistoryDetailState(error: roomResult.failureOrNull?.message));
      return;
    }

    final ordersResult = await _orders.getOrders(roomId);
    final receiptResult = await _receipts.getReceipt(roomId);
    final costResult = await _costs.getCostShare(roomId);
    final suggestionsResult = await _suggestions.getSuggestions(roomId);

    final winnerId = room.winnerSuggestionId;
    final restaurant = suggestionsResult.dataOrNull
        ?.where((s) => s.id == winnerId)
        .firstOrNull
        ?.name;

    emit(
      HistoryDetailState(
        room: room,
        restaurantName: restaurant,
        orders: ordersResult.dataOrNull ?? const [],
        receipt: receiptResult.dataOrNull,
        costShare: costResult.dataOrNull,
      ),
    );
  }
}
