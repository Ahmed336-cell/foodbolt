import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../room/domain/entities/room.dart';
import '../../../room/domain/usecases/room_usecases.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.rooms = const [],
    this.loading = false,
    this.error,
  });

  final List<Room> rooms;
  final bool loading;
  final String? error;

  @override
  List<Object?> get props => [rooms, loading, error];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit(this._getHistory) : super(const HistoryState());

  final GetRoomHistory _getHistory;

  Future<void> load() async {
    emit(const HistoryState(loading: true));
    final result = await _getHistory(const NoParams());
    result.fold(
      (f) => emit(HistoryState(error: f.message)),
      (rooms) => emit(HistoryState(rooms: rooms)),
    );
  }
}
