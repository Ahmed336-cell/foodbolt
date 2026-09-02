import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/numeric_input.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../domain/entities/user_order.dart';
import '../cubit/order_cubit.dart';

class OrderEntryScreen extends StatelessWidget {
  const OrderEntryScreen({super.key});

  Future<void> _addItem(BuildContext context) async {
    final name = TextEditingController();
    final price = TextEditingController();
    final qty = TextEditingController(text: '1');
    final notes = TextEditingController();

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionPrompt(text: ctx.l10n.addItem),
            TextField(
              controller: name,
              decoration: InputDecoration(hintText: ctx.l10n.itemName),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: qty,
              keyboardType: NumericInput.intKeyboard,
              inputFormatters: NumericInput.intOnly,
              decoration: InputDecoration(hintText: ctx.l10n.quantity),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: price,
              keyboardType: NumericInput.decimalKeyboard,
              inputFormatters: NumericInput.decimal,
              decoration: InputDecoration(hintText: ctx.l10n.priceEgp),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              decoration: InputDecoration(hintText: ctx.l10n.notes),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: ctx.l10n.add,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (ok == true && context.mounted) {
      context.read<OrderCubit>().addDraftItem(
        name: name.text,
        quantity: int.tryParse(qty.text) ?? 1,
        price: double.tryParse(price.text) ?? 0,
        notes: notes.text.isEmpty ? null : notes.text,
      );
    }
  }

  Future<void> _copyOrder(BuildContext context) async {
    final cubit = context.read<OrderCubit>();
    final text = cubit.copyText(currency: context.l10n.currency);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.orderCopied)));
  }

  Future<void> _submit(BuildContext context) async {
    final cubit = context.read<OrderCubit>();
    final l10n = context.l10n;
    if (cubit.state.draftItems.isEmpty) {
      final ok = await showAppConfirmDialog(
        context,
        title: l10n.emptyOrderTitle,
        message: l10n.emptyOrderBody,
        confirmLabel: l10n.sendEmptyOrder,
        icon: Icons.shopping_bag_outlined,
      );
      if (ok != true || !context.mounted) return;
    }
    await cubit.submit();
  }

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final user = context.watch<AuthCubit>().state.user;
    final isHost = room.hostId == user?.id;
    final winner = context
        .watch<SuggestionCubit>()
        .state
        .items
        .where((s) => s.id == room.winnerSuggestionId)
        .firstOrNull;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.yourOrder)),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          final items = state.displayItems;
          return AdaptivePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.orderingFrom(winner?.name ?? '')),
                const SizedBox(height: 8),
                SectionPrompt(
                  text: state.isSubmitted
                      ? l10n.yourSubmittedOrder
                      : l10n.whatDoYouWant,
                ),
                if (state.error != null) ErrorBanner(message: state.error!),
                if (state.info != null) InfoBanner(message: state.info!),
                if (state.isSubmitted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      l10n.orderSubmitted,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                if (!state.isSubmitted && state.savedTemplates.isNotEmpty) ...[
                  Text(
                    l10n.savedOrders,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.savedTemplates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final t = state.savedTemplates[i];
                        return InputChip(
                          label: Text(t.title),
                          onPressed: () =>
                              context.read<OrderCubit>().applySavedTemplate(t),
                          onDeleted: () => context
                              .read<OrderCubit>()
                              .deleteSavedTemplate(t.id),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (items.isEmpty)
                        EmptyStateView(message: l10n.noItemsYet)
                      else
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _OrderItemTile(
                              item: item,
                              readOnly: state.isSubmitted,
                              onRemove: () => context
                                  .read<OrderCubit>()
                                  .removeDraftItem(item.id),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _GroupOrdersList(
                        state: state,
                        members: context
                            .watch<RoomCubit>()
                            .state
                            .members
                            .length,
                      ),
                    ],
                  ),
                ),
                if (!state.isSubmitted) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton.extended(
                      onPressed: () => _addItem(context),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addYourOrderItems),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.subtotal,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    MoneyText(state.draftSubtotal),
                  ],
                ),
                const SizedBox(height: 12),
                if (state.isSubmitted) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: l10n.copyOrder,
                          onPressed: () => _copyOrder(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SecondaryButton(
                          label: l10n.saveOrderForNext,
                          onPressed: () => context
                              .read<OrderCubit>()
                              .saveCurrentAsTemplate(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: l10n.editOrder,
                    onPressed: () =>
                        context.read<OrderCubit>().startEditingSubmitted(),
                  ),
                ] else
                  PrimaryButton(
                    label: l10n.submitMyOrder,
                    loading: state.loading,
                    onPressed: () => _submit(context),
                  ),
                if (isHost) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: l10n.lockOrders,
                    onPressed: state.loading
                        ? null
                        : () async {
                            final ok = await showAppConfirmDialog(
                              context,
                              title: l10n.lockOrdersQuestion,
                              message: l10n.lockOrdersBody,
                              confirmLabel: l10n.lock,
                              icon: Icons.lock_outline_rounded,
                            );
                            if (ok == true && context.mounted) {
                              await context.read<OrderCubit>().lock();
                            }
                          },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({
    required this.item,
    required this.readOnly,
    required this.onRemove,
  });

  final OrderItem item;
  final bool readOnly;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('${item.name} ×${item.quantity}'),
      subtitle: item.notes == null || item.notes!.isEmpty
          ? Text(
              '${item.price.toStringAsFixed(0)} ${context.l10n.currency}',
              style: const TextStyle(color: AppTheme.textSecondary),
            )
          : Text(item.notes!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoneyText(item.lineTotal),
          if (!readOnly)
            IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
        ],
      ),
    );
  }
}

class _GroupOrdersList extends StatelessWidget {
  const _GroupOrdersList({required this.state, required this.members});

  final OrderState state;
  final int members;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final orders = [...state.allOrders]
      ..sort((a, b) {
        if (a.submitted != b.submitted) return a.submitted ? -1 : 1;
        return a.displayName.compareTo(b.displayName);
      });

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.groupOrders,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.ordersSubmitted(state.submittedCount, members),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (orders.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                l10n.notSubmitted,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...orders.map(
              (o) => ListTile(
                dense: true,
                title: Text(o.displayName),
                subtitle: Text(
                  o.submitted
                      ? o.items
                            .map((i) => '${i.name} ×${i.quantity}')
                            .join(', ')
                      : l10n.notSubmitted,
                ),
                trailing: MoneyText(o.subtotal),
              ),
            ),
        ],
      ),
    );
  }
}
