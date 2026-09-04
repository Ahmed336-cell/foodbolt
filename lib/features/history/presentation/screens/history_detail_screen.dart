import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../orders/domain/entities/user_order.dart';
import '../../../receipt/domain/entities/receipt.dart';
import '../../../receipt/presentation/widgets/receipt_photo.dart';
import '../cubit/history_detail_cubit.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<HistoryDetailCubit>()..load(roomId),
      child: const _HistoryDetailView(),
    );
  }
}

class _HistoryDetailView extends StatelessWidget {
  const _HistoryDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.historyDetailTitle)),
      bottomNavigationBar: const AdBanner(),
      body: BlocBuilder<HistoryDetailCubit, HistoryDetailState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: ErrorBanner(message: state.error!));
          }
          final room = state.room;
          if (room == null) {
            return Center(child: EmptyStateView(message: l10n.errRoomNotFound));
          }

          final submitted = state.orders
              .where((o) => o.submitted)
              .toList();
          final receipt = state.receipt;
          final photo = ReceiptPhoto(
            imageUrl: receipt?.imageUrl,
            localPath: receipt?.localPath,
            height: 220,
            empty: receipt?.status == ReceiptStatus.uploaded
                ? Center(child: Text(l10n.historyNoReceipt))
                : null,
          );

          return AppScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  room.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${room.createdAt.toLocal().toString().split('.').first}'
                  ' · ${room.code}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                if (state.restaurantName != null &&
                    state.restaurantName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.restaurantName!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                if (photo.hasImage) ...[
                  const SizedBox(height: 16),
                  Text(
                    l10n.uploadReceiptTitle,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  photo,
                ],
                const SizedBox(height: 20),
                Text(
                  l10n.perPersonOrders,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                if (submitted.isEmpty)
                  Text(l10n.noItemsYet)
                else
                  ...submitted.map((o) => _personCard(context, o)),
                if (state.costShare != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    l10n.costSharing,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  _row(l10n.receiptTotal, state.costShare!.receiptTotal),
                  _row(l10n.expectedOrders, state.costShare!.expectedOrdersTotal),
                  ...state.costShare!.shares.map(
                    (s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.displayName),
                      subtitle: Text(
                        l10n.orderPlusExtras(
                          s.orderSubtotal.toStringAsFixed(0),
                          s.extrasShare.toStringAsFixed(0),
                        ),
                      ),
                      trailing: MoneyText(s.finalAmount),
                    ),
                  ),
                  _row(l10n.sharesTotal, state.costShare!.sharesTotal),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _personCard(BuildContext context, UserOrder order) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.displayName,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              if (order.items.isEmpty)
                Text(
                  l10n.noItemsYet,
                  style: const TextStyle(color: AppTheme.textSecondary),
                )
              else
                ...order.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '• ${item.name} ×${item.quantity}'
                            '${item.notes == null || item.notes!.isEmpty ? '' : ' (${item.notes})'}',
                          ),
                        ),
                        MoneyText(item.lineTotal),
                      ],
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: MoneyText(order.subtotal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          MoneyText(value),
        ],
      ),
    );
  }
}
