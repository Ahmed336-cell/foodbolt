import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ads/ad_banner.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/localization/l10n_extension.dart';
import '../../../../core/widgets/app_page.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../cubit/history_cubit.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => sl<HistoryCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.historyTitle)),
        bottomNavigationBar: const AdBanner(),
        body: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null) {
              return Center(child: ErrorBanner(message: state.error!));
            }
            if (state.rooms.isEmpty) {
              return EmptyStateView(message: l10n.noCompletedRooms);
            }
            return AdaptivePadding(
              top: 8,
              bottom: 16,
              child: ListView.separated(
                itemCount: state.rooms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final room = state.rooms[i];
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(room.name),
                    subtitle: Text(
                      '${room.createdAt.toLocal().toString().split('.').first} · ${room.code}',
                    ),
                    onTap: () => context.push('/history/${room.id}'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
