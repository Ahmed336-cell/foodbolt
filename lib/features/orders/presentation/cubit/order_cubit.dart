import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/saved_order_template.dart';
import '../../domain/entities/user_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/saved_orders_repository.dart';
import '../../domain/usecases/order_usecases.dart';

class OrderState extends Equatable {
  const OrderState({
    this.myOrder,
    this.allOrders = const [],
    this.draftItems = const [],
    this.savedTemplates = const [],
    this.loading = false,
    this.error,
    this.info,
    this.submittedMessage = false,
    this.editingSubmitted = false,
  });

  final UserOrder? myOrder;
  final List<UserOrder> allOrders;
  final List<OrderItem> draftItems;
  final List<SavedOrderTemplate> savedTemplates;
  final bool loading;
  final String? error;
  final String? info;
  final bool submittedMessage;
  final bool editingSubmitted;

  bool get isSubmitted => myOrder?.submitted == true && !editingSubmitted;

  List<OrderItem> get displayItems =>
      isSubmitted ? (myOrder?.items ?? draftItems) : draftItems;

  double get draftSubtotal =>
      displayItems.fold(0, (s, i) => s + i.lineTotal);

  int get submittedCount => allOrders.where((o) => o.submitted).length;

  OrderState copyWith({
    UserOrder? myOrder,
    List<UserOrder>? allOrders,
    List<OrderItem>? draftItems,
    List<SavedOrderTemplate>? savedTemplates,
    bool? loading,
    String? error,
    String? info,
    bool? submittedMessage,
    bool? editingSubmitted,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return OrderState(
      myOrder: myOrder ?? this.myOrder,
      allOrders: allOrders ?? this.allOrders,
      draftItems: draftItems ?? this.draftItems,
      savedTemplates: savedTemplates ?? this.savedTemplates,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      info: clearInfo ? null : (info ?? this.info),
      submittedMessage: submittedMessage ?? this.submittedMessage,
      editingSubmitted: editingSubmitted ?? this.editingSubmitted,
    );
  }

  @override
  List<Object?> get props => [
        myOrder,
        allOrders,
        draftItems,
        savedTemplates,
        loading,
        error,
        info,
        submittedMessage,
        editingSubmitted,
      ];
}

class OrderCubit extends Cubit<OrderState> {
  OrderCubit({
    required OrderRepository repository,
    required SavedOrdersRepository savedOrdersRepository,
    required GetMyOrder getMyOrder,
    required SubmitOrder submitOrder,
    required LockOrders lockOrders,
    required UpdateOrderItemPrice updateOrderItemPrice,
  })  : _repository = repository,
        _savedOrders = savedOrdersRepository,
        _getMyOrder = getMyOrder,
        _submitOrder = submitOrder,
        _lockOrders = lockOrders,
        _updateOrderItemPrice = updateOrderItemPrice,
        super(const OrderState());

  final OrderRepository _repository;
  final SavedOrdersRepository _savedOrders;
  final GetMyOrder _getMyOrder;
  final SubmitOrder _submitOrder;
  final LockOrders _lockOrders;
  final UpdateOrderItemPrice _updateOrderItemPrice;
  final _uuid = const Uuid();
  StreamSubscription<List<UserOrder>>? _sub;
  String? _roomId;

  Future<void> watch(String roomId, String userId) async {
    _roomId = roomId;
    await loadSavedTemplates();
    final mine = await _getMyOrder(roomId);
    mine.fold(
      (f) => emit(state.copyWith(error: f.message)),
      (order) => emit(
        state.copyWith(
          myOrder: order,
          draftItems: order.items,
          submittedMessage: order.submitted,
        ),
      ),
    );
    _sub?.cancel();
    _sub = _repository.watchOrders(roomId).listen((orders) {
      final mine = orders.where((o) => o.userId == userId).firstOrNull;
      emit(
        state.copyWith(
          allOrders: orders,
          myOrder: mine ?? state.myOrder,
          submittedMessage: mine?.submitted ?? state.submittedMessage,
          draftItems: mine != null && mine.submitted
              ? mine.items
              : state.draftItems,
        ),
      );
    });
  }

  Future<void> loadSavedTemplates() async {
    final templates = await _savedOrders.loadAll();
    emit(state.copyWith(savedTemplates: templates));
  }

  void addDraftItem({
    required String name,
    required int quantity,
    required double price,
    String? notes,
  }) {
    if (name.trim().isEmpty) return;
    final item = OrderItem(
      id: _uuid.v4(),
      name: name.trim(),
      quantity: quantity < 1 ? 1 : quantity,
      price: price,
      notes: notes,
    );
    emit(state.copyWith(draftItems: [...state.draftItems, item]));
  }

  void removeDraftItem(String id) {
    emit(
      state.copyWith(
        draftItems: state.draftItems.where((i) => i.id != id).toList(),
      ),
    );
  }

  void applySavedTemplate(SavedOrderTemplate template) {
    final items = [
      for (final i in template.items)
        OrderItem(
          id: _uuid.v4(),
          name: i.name,
          quantity: i.quantity,
          price: i.price,
          notes: i.notes,
        ),
    ];
    emit(
      state.copyWith(
        draftItems: items,
        clearInfo: true,
        info: 'Saved order loaded.',
      ),
    );
  }

  Future<bool> saveCurrentAsTemplate({String? title}) async {
    final items = state.displayItems;
    if (items.isEmpty) {
      emit(state.copyWith(error: 'No items to save.'));
      return false;
    }
    final template = SavedOrderTemplate(
      id: _uuid.v4(),
      title: (title == null || title.trim().isEmpty)
          ? items.map((i) => i.name).take(3).join(', ')
          : title.trim(),
      items: [
        for (final i in items)
          OrderItem(
            id: _uuid.v4(),
            name: i.name,
            quantity: i.quantity,
            price: i.price,
            notes: i.notes,
          ),
      ],
      savedAt: DateTime.now(),
    );
    await _savedOrders.save(template);
    await loadSavedTemplates();
    emit(state.copyWith(info: 'Order saved for next time.', clearError: true));
    return true;
  }

  Future<void> deleteSavedTemplate(String id) async {
    await _savedOrders.delete(id);
    await loadSavedTemplates();
  }

  String copyText({String currency = 'EGP'}) =>
      state.displayItems.toCopyText(currency: currency);

  Future<bool> submit() async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true, clearInfo: true));
    final result = await _submitOrder(
      SubmitOrderParams(
        roomId: roomId,
        items: state.draftItems,
        submit: true,
      ),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (order) {
        emit(
          state.copyWith(
            myOrder: order,
            draftItems: order.items,
            loading: false,
            submittedMessage: true,
            editingSubmitted: false,
          ),
        );
        return true;
      },
    );
  }

  void startEditingSubmitted() {
    final items = state.myOrder?.items ?? state.draftItems;
    emit(
      state.copyWith(
        draftItems: List.of(items),
        editingSubmitted: true,
        submittedMessage: false,
      ),
    );
  }

  Future<bool> lock() async {
    final roomId = _roomId;
    if (roomId == null) return false;
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _lockOrders(roomId);
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  Future<bool> updateItemPrice(String itemId, double price) async {
    emit(state.copyWith(loading: true, clearError: true));
    final result = await _updateOrderItemPrice(
      UpdateItemPriceParams(itemId: itemId, price: price),
    );
    return result.fold(
      (f) {
        emit(state.copyWith(loading: false, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(loading: false));
        return true;
      },
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
