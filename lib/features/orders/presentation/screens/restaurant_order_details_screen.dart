import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../domain/aggregate_order_items.dart';
import '../../domain/repositories/saved_orders_repository.dart';
import '../cubit/order_cubit.dart';

/// Shown after orders are locked — copy/share the combined ticket to the restaurant.
class RestaurantOrderDetailsScreen extends StatelessWidget {
  const RestaurantOrderDetailsScreen({super.key});

  Future<void> _copy(BuildContext context, String text) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.orderDetailsCopied)),
    );
  }

  Future<void> _share(String text) async {
    if (text.isEmpty) return;
    await SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final winner = context
        .watch<SuggestionCubit>()
        .state
        .items
        .where((s) => s.id == room.winnerSuggestionId)
        .firstOrNull;
    final restaurant = winner?.name ?? context.l10n.appName;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orderDetailsTitle)),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          final submitted = state.allOrders
              .where((o) => o.submitted && o.items.isNotEmpty)
              .toList();
          final grandTotal =
              submitted.fold<double>(0, (s, o) => s + o.subtotal);
          final ticket = state.allOrders.toRestaurantOrderText(
            restaurantName: restaurant,
            currency: l10n.currency,
          );
          final aggregated = aggregateOrderItems(state.allOrders);

          return AdaptivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.orderDetailsPrompt,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        l10n.combinedOrder,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.combinedOrderHint,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (aggregated.isEmpty)
                                Text(l10n.noItemsYet)
                              else
                                ...aggregated.map((line) {
                                  final notes = line.notes;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: line.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '  ×${line.qty}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        fontSize: 15,
                                                        color: line.isShared
                                                            ? AppTheme.primary
                                                            : AppTheme
                                                                .textPrimary,
                                                      ),
                                                    ),
                                                    if (notes != null &&
                                                        notes.isNotEmpty)
                                                      TextSpan(
                                                        text: '  ($notes)',
                                                        style: const TextStyle(
                                                          color: AppTheme
                                                              .textSecondary,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                line.isShared
                                                    ? l10n.sharedBy(
                                                        line.peopleSummary,
                                                      )
                                                    : l10n.orderedBy(
                                                        line.peopleSummary,
                                                      ),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: line.isShared
                                                      ? FontWeight.w600
                                                      : FontWeight.w500,
                                                  color: line.isShared
                                                      ? AppTheme.primary
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        MoneyText(line.total),
                                      ],
                                    ),
                                  );
                                }),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Text(
                                    l10n.total,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  MoneyText(grandTotal),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.perPersonOrders,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...submitted.map(
                        (o) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    o.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...o.items.map(
                                    (item) => Text(
                                      '• ${item.name} ×${item.quantity} — '
                                      '${item.lineTotal.toStringAsFixed(0)} ${l10n.currency}'
                                      '${item.notes == null || item.notes!.isEmpty ? '' : ' (${item.notes})'}',
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: MoneyText(o.subtotal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.copyOrder,
                        onPressed: ticket.isEmpty
                            ? null
                            : () => _copy(context, ticket),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SecondaryButton(
                        label: l10n.shareWithRestaurant,
                        onPressed:
                            ticket.isEmpty ? null : () => _share(ticket),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (isHost)
                  PrimaryButton(
                    label: l10n.continueToReceipt,
                    onPressed: () => context
                        .read<RoomCubit>()
                        .advancePhase(RoomPhase.receipt),
                  )
                else
                  Text(
                    l10n.waitingHostReceipt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
