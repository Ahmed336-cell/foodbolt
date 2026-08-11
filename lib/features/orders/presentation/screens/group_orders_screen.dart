import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../cubit/order_cubit.dart';

class GroupOrdersScreen extends StatelessWidget {
  const GroupOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == context.watch<AuthCubit>().state.user?.id;
    final memberCount = context.watch<RoomCubit>().state.members.length;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupOrders)),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          return AdaptivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionPrompt(
                  text: l10n.ordersSubmitted(state.submittedCount, memberCount),
                ),
                if (state.error != null) ErrorBanner(message: state.error!),
                Expanded(
                  child: ListView.separated(
                    itemCount: state.allOrders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = state.allOrders[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    o.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  Chip(
                                    label: Text(
                                      o.submitted
                                          ? l10n.submitted
                                          : l10n.notSubmitted,
                                    ),
                                  ),
                                ],
                              ),
                              ...o.items.map(
                                (item) => Text(
                                  '• ${item.name} ×${item.quantity} — '
                                  '${item.lineTotal.toStringAsFixed(0)} ${l10n.currency}',
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: MoneyText(o.subtotal),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isHost)
                  PrimaryButton(
                    label: l10n.lockOrders,
                    loading: state.loading,
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.lockOrdersQuestion),
                          content: Text(l10n.lockOrdersBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.lock),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        await context.read<OrderCubit>().lock();
                      }
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
