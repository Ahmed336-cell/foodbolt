import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../mock/mock_app_store.dart';
import '../supabase/supabase_bootstrap.dart';
import '../../features/auth/data/repositories/auth_mock_repository.dart';
import '../../features/auth/data/repositories/auth_supabase_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/cost_sharing/data/repositories/cost_sharing_mock_repository.dart';
import '../../features/cost_sharing/data/repositories/cost_sharing_supabase_repository.dart';
import '../../features/cost_sharing/domain/repositories/cost_sharing_repository.dart';
import '../../features/cost_sharing/domain/usecases/cost_sharing_usecases.dart';
import '../../features/cost_sharing/presentation/cubit/cost_sharing_cubit.dart';
import '../../features/deep_link/data/repositories/deep_link_mock_repository.dart';
import '../../features/deep_link/data/repositories/deep_link_supabase_repository.dart';
import '../../features/deep_link/domain/repositories/deep_link_repository.dart';
import '../../features/deep_link/presentation/cubit/deep_link_cubit.dart';
import '../../features/history/presentation/cubit/history_cubit.dart';
import '../../features/history/presentation/cubit/history_detail_cubit.dart';
import '../../features/orders/data/repositories/order_mock_repository.dart';
import '../../features/orders/data/repositories/order_supabase_repository.dart';
import '../../features/orders/data/repositories/saved_orders_prefs_repository.dart';
import '../../features/orders/domain/repositories/order_repository.dart';
import '../../features/orders/domain/repositories/saved_orders_repository.dart';
import '../../features/orders/domain/usecases/order_usecases.dart';
import '../../features/orders/presentation/cubit/order_cubit.dart';
import '../../features/payment_summary/data/repositories/payment_mock_repository.dart';
import '../../features/payment_summary/data/repositories/payment_supabase_repository.dart';
import '../../features/payment_summary/domain/repositories/payment_repository.dart';
import '../../features/payment_summary/domain/usecases/payment_usecases.dart';
import '../../features/payment_summary/presentation/cubit/payment_summary_cubit.dart';
import '../../features/race/data/repositories/race_mock_repository.dart';
import '../../features/race/data/repositories/race_supabase_repository.dart';
import '../../features/race/domain/repositories/race_repository.dart';
import '../../features/race/domain/usecases/race_usecases.dart';
import '../../features/race/presentation/cubit/race_cubit.dart';
import '../../features/receipt/data/repositories/receipt_mock_repository.dart';
import '../../features/receipt/data/repositories/receipt_supabase_repository.dart';
import '../../features/receipt/domain/repositories/receipt_repository.dart';
import '../../features/receipt/domain/usecases/receipt_usecases.dart';
import '../../features/receipt/presentation/cubit/receipt_cubit.dart';
import '../../features/room/data/repositories/room_mock_repository.dart';
import '../../features/room/data/repositories/room_supabase_repository.dart';
import '../../features/settings/data/repositories/settings_prefs_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/settings_usecases.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/room/domain/repositories/room_repository.dart';
import '../../features/room/domain/usecases/room_usecases.dart';
import '../../features/room/presentation/cubit/room_cubit.dart';
import '../../features/suggestions/data/repositories/suggestion_mock_repository.dart';
import '../../features/suggestions/data/repositories/suggestion_supabase_repository.dart';
import '../../features/suggestions/domain/repositories/suggestion_repository.dart';
import '../../features/suggestions/domain/usecases/suggestion_usecases.dart';
import '../../features/suggestions/presentation/cubit/suggestion_cubit.dart';
import '../../features/voting/data/repositories/voting_mock_repository.dart';
import '../../features/voting/data/repositories/voting_supabase_repository.dart';
import '../../features/voting/domain/repositories/voting_repository.dart';
import '../../features/voting/domain/usecases/voting_usecases.dart';
import '../../features/voting/presentation/cubit/voting_cubit.dart';

final sl = GetIt.instance;

Future<void> configureDependencies({bool? useMocks}) async {
  var mocks = useMocks ?? AppEnv.useMocks;
  AppEnv.liveBackendRequestedButUnavailable = false;
  AppEnv.backendError = null;

  if (!mocks) {
    if (!AppEnv.hasSupabaseCredentials) {
      AppEnv.liveBackendRequestedButUnavailable = true;
      AppEnv.backendError =
          'USE_MOCKS=false but SUPABASE_URL / SUPABASE_ANON_KEY missing. '
          'Copy secrets into assets/env/.env (and root .env), then full restart '
          '(flutter clean && flutter run).';
      debugPrint('Supabase: ${AppEnv.backendError}');
      // Do NOT silent-fallback to mocks — that creates rooms only in memory.
      throw StateError(AppEnv.backendError!);
    }
    try {
      final ready = await SupabaseBootstrap.init();
      if (!ready) {
        AppEnv.liveBackendRequestedButUnavailable = true;
        AppEnv.backendError =
            'Supabase init failed. Check SUPABASE_URL / SUPABASE_ANON_KEY.';
        debugPrint('Supabase: ${AppEnv.backendError}');
        throw StateError(AppEnv.backendError!);
      }
    } catch (e, st) {
      if (e is StateError && AppEnv.backendError != null) rethrow;
      AppEnv.liveBackendRequestedButUnavailable = true;
      AppEnv.backendError = 'Supabase init error: $e';
      debugPrint('Supabase: init exception\n$e\n$st');
      throw StateError(AppEnv.backendError!);
    }
  }

  AppEnv.usingMocks = mocks;
  debugPrint(
    mocks
        ? 'Backend: MOCKS (in-memory — rooms not in Supabase)'
        : 'Backend: LIVE Supabase',
  );

  if (sl.isRegistered<MockAppStore>() || sl.isRegistered<AuthRepository>()) {
    await sl.reset();
  }

  sl.registerLazySingleton<SettingsRepository>(SettingsPrefsRepository.new);
  sl.registerLazySingleton<SavedOrdersRepository>(SavedOrdersPrefsRepository.new);

  if (mocks) {
    _registerMocks();
  } else {
    _registerSupabase(SupabaseBootstrap.client);
  }

  _registerUseCasesAndCubits();
}

void _registerMocks() {
  sl.registerLazySingleton<MockAppStore>(MockAppStore.new);
  sl.registerLazySingleton<AuthRepository>(() => AuthMockRepository(sl()));
  sl.registerLazySingleton<RoomRepository>(() => RoomMockRepository(sl()));
  sl.registerLazySingleton<SuggestionRepository>(
    () => SuggestionMockRepository(sl()),
  );
  sl.registerLazySingleton<VotingRepository>(() => VotingMockRepository(sl()));
  sl.registerLazySingleton<RaceRepository>(() => RaceMockRepository(sl()));
  sl.registerLazySingleton<OrderRepository>(() => OrderMockRepository(sl()));
  sl.registerLazySingleton<ReceiptRepository>(() => ReceiptMockRepository(sl()));
  sl.registerLazySingleton<CostSharingRepository>(
    () => CostSharingMockRepository(sl()),
  );
  sl.registerLazySingleton<PaymentRepository>(() => PaymentMockRepository(sl()));
  sl.registerLazySingleton<DeepLinkRepository>(
    () => DeepLinkMockRepository(sl()),
  );
}

void _registerSupabase(SupabaseClient client) {
  sl.registerLazySingleton<SupabaseClient>(() => client);
  sl.registerLazySingleton<AuthRepository>(
    () => AuthSupabaseRepository(client),
  );
  sl.registerLazySingleton<RoomRepository>(
    () => RoomSupabaseRepository(client),
  );
  sl.registerLazySingleton<SuggestionRepository>(
    () => SuggestionSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<VotingRepository>(
    () => VotingSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<RaceRepository>(
    () => RaceSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<ReceiptRepository>(
    () => ReceiptSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<CostSharingRepository>(
    () => CostSharingSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<PaymentRepository>(
    () => PaymentSupabaseRepository(client: client),
  );
  sl.registerLazySingleton<DeepLinkRepository>(
    () => DeepLinkSupabaseRepository(client: client),
  );
}

void _registerUseCasesAndCubits() {
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => ContinueAsGuest(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => DeleteAccount(sl()));

  sl.registerLazySingleton(() => CreateRoom(sl()));
  sl.registerLazySingleton(() => JoinRoom(sl()));
  sl.registerLazySingleton(() => JoinRoomById(sl()));
  sl.registerLazySingleton(() => GetRoom(sl()));
  sl.registerLazySingleton(() => SetRoomPhase(sl()));
  sl.registerLazySingleton(() => SetRoomSelectionMode(sl()));
  sl.registerLazySingleton(() => GetInviteLink(sl()));
  sl.registerLazySingleton(() => LeaveRoom(sl()));
  sl.registerLazySingleton(() => GetRoomHistory(sl()));

  sl.registerLazySingleton(() => AddRestaurantSuggestion(sl()));
  sl.registerLazySingleton(() => RemoveRestaurantSuggestion(sl()));
  sl.registerLazySingleton(() => VoteRestaurant(sl()));
  sl.registerLazySingleton(() => RevealVoteWinner(sl()));
  sl.registerLazySingleton(() => PickTiedWinner(sl()));
  sl.registerLazySingleton(() => PrepareRace(sl()));
  sl.registerLazySingleton(() => StartRace(sl()));
  sl.registerLazySingleton(() => GetMyOrder(sl()));
  sl.registerLazySingleton(() => SubmitOrder(sl()));
  sl.registerLazySingleton(() => LockOrders(sl()));
  sl.registerLazySingleton(() => UpdateOrderItemPrice(sl()));
  sl.registerLazySingleton(() => UploadReceipt(sl()));
  sl.registerLazySingleton(() => SkipReceipt(sl()));
  sl.registerLazySingleton(() => CalculateCostSharing(sl()));
  sl.registerLazySingleton(() => ConfirmCostSharing(sl()));
  sl.registerLazySingleton(() => MarkPaymentAsPaid(sl()));
  sl.registerLazySingleton(() => RequestPayment(sl()));
  sl.registerLazySingleton(() => MarkPaymentAsUnpaid(sl()));

  sl.registerLazySingleton(
    () => AuthCubit(
      authRepository: sl(),
      getCurrentUser: sl(),
      loginUser: sl(),
      registerUser: sl(),
      continueAsGuest: sl(),
      logoutUser: sl(),
      deleteAccount: sl(),
    ),
  );
  sl.registerLazySingleton(() => DeepLinkCubit(sl()));

  sl.registerLazySingleton(() => LoadSettings(sl()));
  sl.registerLazySingleton(() => SaveLocale(sl()));
  sl.registerLazySingleton(() => CompleteOnboarding(sl()));
  sl.registerLazySingleton(() => ResetOnboarding(sl()));
  sl.registerLazySingleton(
    () => SettingsCubit(
      loadSettings: sl(),
      saveLocale: sl(),
      completeOnboarding: sl(),
      resetOnboarding: sl(),
    ),
  );

  sl.registerFactory(
    () => RoomCubit(
      roomRepository: sl(),
      createRoom: sl(),
      joinRoom: sl(),
      joinRoomById: sl(),
      setRoomPhase: sl(),
      setRoomSelectionMode: sl(),
      getInviteLink: sl(),
      leaveRoom: sl(),
    ),
  );
  sl.registerFactory(
    () => SuggestionCubit(
      repository: sl(),
      addSuggestion: sl(),
      removeSuggestion: sl(),
    ),
  );
  sl.registerFactory(
    () => VotingCubit(
      repository: sl(),
      voteRestaurant: sl(),
      revealVoteWinner: sl(),
      pickTiedWinner: sl(),
    ),
  );
  sl.registerFactory(
    () => RaceCubit(
      repository: sl(),
      prepareRace: sl(),
      startRace: sl(),
    ),
  );
  sl.registerFactory(
    () => OrderCubit(
      repository: sl(),
      savedOrdersRepository: sl(),
      getMyOrder: sl(),
      submitOrder: sl(),
      lockOrders: sl(),
      updateOrderItemPrice: sl(),
    ),
  );
  sl.registerFactory(
    () => ReceiptCubit(
      repository: sl(),
      uploadReceipt: sl(),
      skipReceipt: sl(),
    ),
  );
  sl.registerFactory(
    () => CostSharingCubit(
      repository: sl(),
      calculateCostSharing: sl(),
      confirmCostSharing: sl(),
    ),
  );
  sl.registerFactory(
    () => PaymentSummaryCubit(
      repository: sl(),
      requestPayment: sl(),
      markPaymentAsPaid: sl(),
      markPaymentAsUnpaid: sl(),
    ),
  );
  sl.registerFactory(() => HistoryCubit(sl()));
  sl.registerFactory(
    () => HistoryDetailCubit(
      getRoom: sl(),
      orderRepository: sl(),
      receiptRepository: sl(),
      costSharingRepository: sl(),
      suggestionRepository: sl(),
    ),
  );
}
