import '../../../../core/usecase/usecase.dart';
import '../entities/user_order.dart';

abstract class OrderRepository {
  Future<Result<UserOrder>> getMyOrder(String roomId);
  Future<Result<UserOrder>> upsertMyOrder({
    required String roomId,
    required List<OrderItem> items,
    required bool submit,
  });
  Future<Result<void>> lockOrders(String roomId);
  Stream<List<UserOrder>> watchOrders(String roomId);
}
