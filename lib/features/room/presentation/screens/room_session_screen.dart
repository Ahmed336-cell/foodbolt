import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/deep_link/invite_links.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/phase/room_phase.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../cost_sharing/presentation/cubit/cost_sharing_cubit.dart';
import '../../../cost_sharing/presentation/screens/cost_sharing_review_screen.dart';
import '../../../deep_link/presentation/cubit/deep_link_cubit.dart';
import '../../../orders/presentation/cubit/order_cubit.dart';
import '../../../orders/presentation/screens/group_orders_screen.dart';
import '../../../orders/presentation/screens/order_entry_screen.dart';
import '../../../orders/presentation/screens/restaurant_selected_screen.dart';
import '../../../payment_summary/presentation/cubit/payment_summary_cubit.dart';
import '../../../payment_summary/presentation/screens/payment_summary_screen.dart';
import '../../../race/presentation/cubit/race_cubit.dart';
import '../../../race/presentation/screens/restaurant_race_screen.dart';
import '../../../receipt/presentation/cubit/receipt_cubit.dart';
import '../../../receipt/presentation/screens/receipt_upload_screen.dart';
import '../../../suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../../suggestions/presentation/screens/restaurant_suggestion_screen.dart';
import '../../../voting/presentation/cubit/voting_cubit.dart';
import '../../../voting/presentation/screens/voting_flow_screen.dart';
import '../../../voting/presentation/screens/vote_draw_screen.dart';
import '../cubit/room_cubit.dart';
import 'room_lobby_screen.dart';

class RoomSessionScreen extends StatefulWidget {
  const RoomSessionScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<RoomSessionScreen> createState() => _RoomSessionScreenState();
}

class _RoomSessionScreenState extends State<RoomSessionScreen> {
  late final RoomCubit _roomCubit = sl<RoomCubit>();
  late final SuggestionCubit _suggestionCubit = sl<SuggestionCubit>();
  late final VotingCubit _votingCubit = sl<VotingCubit>();
  late final RaceCubit _raceCubit = sl<RaceCubit>();
  late final OrderCubit _orderCubit = sl<OrderCubit>();
  late final ReceiptCubit _receiptCubit = sl<ReceiptCubit>();
  late final CostSharingCubit _costCubit = sl<CostSharingCubit>();
  late final PaymentSummaryCubit _paymentCubit = sl<PaymentSummaryCubit>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    context.read<DeepLinkCubit>().setPending(null);
    final userId = context.read<AuthCubit>().state.user?.id;
    final token = widget.roomId;
    final joined = InviteLinks.looksLikeUuid(token)
        ? await _roomCubit.joinWithId(token)
        : await _roomCubit.joinWithCode(token);

    final roomId = joined?.id ?? _roomCubit.state.room?.id;
    if (roomId == null) return;

    if (joined == null) {
      _roomCubit.watch(roomId);
    }
    _suggestionCubit.watch(roomId);
    _votingCubit.watch(roomId);
    _raceCubit.watch(roomId);
    if (userId != null) {
      await _orderCubit.watch(roomId, userId);
    }
    _receiptCubit.watch(roomId);
    _costCubit.watch(roomId);
    _paymentCubit.watch(roomId);
  }

  @override
  void dispose() {
    _roomCubit.close();
    _suggestionCubit.close();
    _votingCubit.close();
    _raceCubit.close();
    _orderCubit.close();
    _receiptCubit.close();
    _costCubit.close();
    _paymentCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _roomCubit),
        BlocProvider.value(value: _suggestionCubit),
        BlocProvider.value(value: _votingCubit),
        BlocProvider.value(value: _raceCubit),
        BlocProvider.value(value: _orderCubit),
        BlocProvider.value(value: _receiptCubit),
        BlocProvider.value(value: _costCubit),
        BlocProvider.value(value: _paymentCubit),
      ],
      child: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state.joinToast != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.joinToast!)),
            );
            context.read<RoomCubit>().clearToast();
          }
        },
        builder: (context, state) {
          if (state.loading && state.room == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.error != null && state.room == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ErrorBanner(message: state.error!),
                  PrimaryButton(
                    label: 'Back Home',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            );
          }
          final room = state.room;
          if (room == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return switch (room.phase) {
            RoomPhase.lobby => const RoomLobbyScreen(),
            RoomPhase.suggestions => _SuggestionsGate(roomId: room.id),
            RoomPhase.voting => const VotingFlowScreen(),
            RoomPhase.draw => const VoteDrawScreen(),
            RoomPhase.race => const RestaurantRaceScreen(),
            RoomPhase.restaurantSelected => const RestaurantSelectedScreen(),
            RoomPhase.ordering => const OrderEntryScreen(),
            RoomPhase.ordersLocked => const GroupOrdersScreen(),
            RoomPhase.receipt => const ReceiptUploadScreen(),
            RoomPhase.costReview => const CostSharingReviewScreen(),
            RoomPhase.paymentSummary => const PaymentSummaryScreen(),
            RoomPhase.completed => const RoomSummaryScreen(),
          };
        },
      ),
    );
  }
}

class _SuggestionsGate extends StatelessWidget {
  const _SuggestionsGate({required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context) {
    // Mode is chosen at create-room time; always collect suggestions first.
    return const RestaurantSuggestionScreen();
  }
}
