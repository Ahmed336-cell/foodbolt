import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/numeric_input.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../receipt/presentation/cubit/receipt_cubit.dart';
import '../../../receipt/presentation/widgets/receipt_photo.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../domain/entities/cost_share.dart';
import '../cubit/cost_sharing_cubit.dart';

class CostSharingReviewScreen extends StatelessWidget {
  const CostSharingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.watch<AuthCubit>().state.user;
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.costSharing)),
      bottomNavigationBar: const AdBanner(),
      body: BlocBuilder<CostSharingCubit, CostSharingState>(
        builder: (context, state) {
          final draft = state.draft;
          return AppScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Image.asset(AppAssets.billSplit, height: 150)),
                const SizedBox(height: 8),
                SectionPrompt(text: l10n.reviewFinalBill),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final receipt = context.watch<ReceiptCubit>().state;
                    final photo = ReceiptPhoto(
                      localPath: receipt.localPath,
                      imageUrl: receipt.receipt?.imageUrl,
                      height: 200,
                    );
                    if (!photo.hasImage) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: photo,
                    );
                  },
                ),
                if (state.error != null) ErrorBanner(message: state.error!),
                if (isHost &&
                    context.watch<ReceiptCubit>().state.wasSkipped) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8D6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      l10n.skipReceiptFeesHint,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                if (draft != null && isHost) ...[
                  _row(l10n.expectedOrders, draft.expectedOrdersTotal),
                  _row(l10n.receiptTotal, draft.receiptTotal),
                  _row(l10n.difference, draft.difference),
                ],
                if (draft != null && !isHost)
                  _MyShareCard(
                    share: draft.shares
                        .where((share) => share.userId == user?.id)
                        .firstOrNull,
                  ),
                if (draft == null && !isHost) const _CalculatingShareCard(),
                const SizedBox(height: 16),
                if (isHost) ...[
                  Text(
                    l10n.additionalCosts,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  _feeField(
                    context,
                    l10n.delivery,
                    state.extras.deliveryFee,
                    (v) => context.read<CostSharingCubit>().updateExtras(
                      state.extras.copyWith(deliveryFee: v),
                    ),
                  ),
                  _feeField(
                    context,
                    l10n.service,
                    state.extras.serviceFee,
                    (v) => context.read<CostSharingCubit>().updateExtras(
                      state.extras.copyWith(serviceFee: v),
                    ),
                  ),
                  _feeField(
                    context,
                    l10n.tax,
                    state.extras.tax,
                    (v) => context.read<CostSharingCubit>().updateExtras(
                      state.extras.copyWith(tax: v),
                    ),
                  ),
                  _feeField(
                    context,
                    l10n.discount,
                    state.extras.discount,
                    (v) => context.read<CostSharingCubit>().updateExtras(
                      state.extras.copyWith(discount: v),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: l10n.recalculate,
                    onPressed: () =>
                        context.read<CostSharingCubit>().recalculate(),
                  ),
                ],
                const SizedBox(height: 16),
                if (draft != null && isHost) ...[
                  Text(
                    l10n.participants,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  ...draft.shares.map(
                    (s) => ListTile(
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
                  _row(l10n.sharesTotal, draft.sharesTotal),
                ],
                if (isHost) ...[
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l10n.confirmAndSend,
                    loading: state.loading,
                    onPressed: () => context.read<CostSharingCubit>().confirm(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Text(label), const Spacer(), MoneyText(value)]),
    );
  }

  Widget _feeField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        initialValue: value == 0 ? '' : value.toStringAsFixed(0),
        keyboardType: NumericInput.decimalKeyboard,
        inputFormatters: NumericInput.decimal,
        decoration: InputDecoration(labelText: label),
        onChanged: (t) => onChanged(double.tryParse(t) ?? 0),
      ),
    );
  }
}

class _CalculatingShareCard extends StatelessWidget {
  const _CalculatingShareCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              context.l10n.calculatingSplit,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyShareCard extends StatelessWidget {
  const _MyShareCard({required this.share});

  final ParticipantShare? share;

  @override
  Widget build(BuildContext context) {
    final share = this.share;
    final l10n = context.l10n;
    if (share == null) {
      return const _CalculatingShareCard();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.yourTotal,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            MoneyText(
              share.finalAmount,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const Divider(height: 28),
            _ShareDetailRow(label: l10n.orderLabel, value: share.orderSubtotal),
            _ShareDetailRow(label: l10n.extrasFees, value: share.extrasShare),
            if (share.adjustment != 0)
              _ShareDetailRow(label: l10n.adjustment, value: share.adjustment),
          ],
        ),
      ),
    );
  }
}

class _ShareDetailRow extends StatelessWidget {
  const _ShareDetailRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Text(label), const Spacer(), MoneyText(value)]),
    );
  }
}
