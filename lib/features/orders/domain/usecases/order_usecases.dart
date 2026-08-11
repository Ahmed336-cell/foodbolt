import '../../../../core/usecase/usecase.dart';
import '../entities/user_order.dart';
import '../repositories/order_repository.dart';

class SubmitOrder extends UseCase<UserOrder, SubmitOrderParams> {
  SubmitOrder(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<UserOrder>> call(SubmitOrderParams params) =>
      _repo.upsertMyOrder(
        roomId: params.roomId,
        items: params.items,
        submit: params.submit,
      );
}

class SubmitOrderParams {
  const SubmitOrderParams({
    required this.roomId,
    required this.items,
    required this.submit,
  });
  final String roomId;
  final List<OrderItem> items;
  final bool submit;
}

class LockOrders extends UseCase<void, String> {
  LockOrders(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<void>> call(String roomId) => _repo.lockOrders(roomId);
}

class GetMyOrder extends UseCase<UserOrder, String> {
  GetMyOrder(this._repo);
  final OrderRepository _repo;

  @override
  Future<Result<UserOrder>> call(String roomId) => _repo.getMyOrder(roomId);
}
