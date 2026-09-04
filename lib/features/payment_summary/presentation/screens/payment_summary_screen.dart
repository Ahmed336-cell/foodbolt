import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../../core/auth/guest_exit.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cost_sharing/presentation/cubit/cost_sharing_cubit.dart';
import '../../../receipt/presentation/cubit/receipt_cubit.dart';
import '../../../receipt/presentation/widgets/receipt_photo.dart';
import '../../../room/presentation/cubit/room_cubit.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../domain/entities/payment_record.dart';
import '../cubit/payment_summary_cubit.dart';

class PaymentSummaryScreen extends StatelessWidget {
  const PaymentSummaryScreen({super.key});

  String _statusLabel(AppLocalizations l10n, PaymentRecord p) {
    return switch (p.status) {
      PaymentStatus.paid => l10n.paid,
      PaymentStatus.requested => l10n.paymentRequestedStatus,
      PaymentStatus.unpaid => l10n.unpaid,
    };
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final room = context.watch<RoomCubit>().state.room!;
    final isHost = room.hostId == user?.id;
    final draft = context.watch<CostSharingCubit>().state.draft;
    final skipped = context.watch<ReceiptCubit>().state.wasSkipped;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.paymentSummary)),
      bottomNavigationBar: const AdBanner(),
      body: BlocBuilder<PaymentSummaryCubit, PaymentSummaryState>(
        builder: (context, state) {
          final mine =
              state.payments.where((p) => p.userId == user?.id).firstOrNull;
          final share =
              draft?.shares.where((s) => s.userId == user?.id).firstOrNull;

          return AppScrollPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Builder(
                builder: (context) {
                  final receipt = context.watch<ReceiptCubit>().state;
                  final photo = ReceiptPhoto(
                    localPath: receipt.localPath,
                    imageUrl: receipt.receipt?.imageUrl,
                    height: 180,
                  );
                  if (!photo.hasImage) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: photo,
                  );
                },
              ),
              if (skipped) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    l10n.payOwnOrderBanner,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              SectionPrompt(text: l10n.yourTotal),
              const SizedBox(height: 8),
              if (state.error != null) ErrorBanner(message: state.error!),
              Text(
                '${(mine?.amount ?? share?.finalAmount ?? 0).toStringAsFixed(0)} '
                '${l10n.currency}',
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
              ),
              if (share != null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.breakdown,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                _line(l10n.orderLabel, share.orderSubtotal),
                _line(l10n.extrasFees, share.extrasShare),
                if (share.adjustment != 0)
                  _line(l10n.adjustment, share.adjustment),
                _line(l10n.total, share.finalAmount),
              ],
              const SizedBox(height: 24),
              if (mine != null) ...[
                switch (mine.status) {
                  PaymentStatus.unpaid => PrimaryButton(
                      label: l10n.requestPaid,
                      loading: state.loading,
                      onPressed: () => context
                          .read<PaymentSummaryCubit>()
                          .requestPaid(mine.userId),
                    ),
                  PaymentStatus.requested => Text(
                      l10n.paymentRequested,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  PaymentStatus.paid => Text(
                      l10n.statusPaid,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                },
              ],
              const SizedBox(height: 24),
              Text(l10n.everyonePaid(state.paidCount, state.payments.length)),
              ...state.payments.map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(p.displayName),
                  subtitle: Text(_statusLabel(l10n, p)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MoneyText(p.amount),
                      if (isHost) ...[
                        if (p.status != PaymentStatus.paid)
                          IconButton(
                            tooltip: l10n.confirmPaid,
                            icon: const Icon(Icons.check_circle_outline),
                            color: Colors.green,
                            onPressed: state.loading
                                ? null
                                : () => context
                                    .read<PaymentSummaryCubit>()
                                    .markPaid(p.userId),
                          ),
                        if (p.status != PaymentStatus.unpaid)
                          IconButton(
                            tooltip: l10n.markUnpaid,
                            icon: const Icon(Icons.autorenew),
                            onPressed: state.loading
                                ? null
                                : () => context
                                    .read<PaymentSummaryCubit>()
                                    .markUnpaid(p.userId),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            ),
          );
        },
      ),
    );
  }

  Widget _line(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          MoneyText(amount),
        ],
      ),
    );
  }
}

class RoomSummaryScreen extends StatelessWidget {
  const RoomSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final room = context.watch<RoomCubit>().state.room!;
    final members = context.watch<RoomCubit>().state.members;
    final payments = context.watch<PaymentSummaryCubit>().state.payments;
    final winner = context
        .watch<SuggestionCubit>()
        .state
        .items
        .where((s) => s.id == room.winnerSuggestionId)
        .firstOrNull;
    final paid = payments.where((p) => p.paid).length;
    final total = payments.fold<double>(0, (s, p) => s + p.amount);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      bottomNavigationBar: const AdBanner(),
      body: AdaptivePadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.roomCompleteTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.roomCompleteBody,
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              winner?.name ?? '',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            Text(l10n.participantsCount(members.length)),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final receipt = context.watch<ReceiptCubit>().state;
                final photo = ReceiptPhoto(
                  localPath: receipt.localPath,
                  imageUrl: receipt.receipt?.imageUrl,
                  height: 180,
                );
                if (!photo.hasImage) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: photo,
                );
              },
            ),
            MoneyText(
              total,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            Text(l10n.paidCount(paid, payments.length)),
            Text(l10n.remainingCount(payments.length - paid, payments.length)),
            const Spacer(),
            PrimaryButton(
              label: l10n.backToHome,
              onPressed: () => leaveToHomeOrOnboarding(context),
            ),
          ],
        ),
      ),
    );
  }
}
