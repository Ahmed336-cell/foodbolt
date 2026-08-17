import '../../../../core/error/failures.dart';
import '../../../../core/mock/mock_app_store.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/restaurant_suggestion.dart';
import '../../domain/repositories/suggestion_repository.dart';

class SuggestionMockRepository implements SuggestionRepository {
  SuggestionMockRepository(this._store);
  final MockAppStore _store;

  @override
  Future<Result<RestaurantSuggestion>> addSuggestion({
    required String roomId,
    required String name,
    String? category,
    String? note,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final memberResult = _store.requireMember(roomId, userResult.dataOrNull!.id);
    if (memberResult case Failed(:final failure)) return Failed(failure);
    final roomResult = _store.requireRoom(roomId);
    if (roomResult case Failed(:final failure)) return Failed(failure);
    final room = roomResult.dataOrNull!;
    if (!room.settings.allowMemberSuggestions &&
        room.hostId != userResult.dataOrNull!.id) {
      return const Failed(PermissionFailure());
    }
    final list = _store.suggestions[roomId] ?? [];
    if (list.length >= room.settings.maxSuggestions) {
      return const Failed(ValidationFailure('Suggestion limit reached.'));
    }
    if (name.trim().isEmpty) {
      return const Failed(ValidationFailure('Restaurant name required.'));
    }
    final user = userResult.dataOrNull!;
    final suggestion = RestaurantSuggestion(
      id: _store.newId(),
      roomId: roomId,
      name: name.trim(),
      category: category,
      note: note,
      suggestedBy: user.id,
      suggestedByName: user.displayName,
    );
    list.add(suggestion);
    _store.suggestions[roomId] = list;
    _store.emitSuggestions(roomId);
    return Success(suggestion);
  }

  @override
  Future<Result<void>> removeSuggestion({
    required String roomId,
    required String suggestionId,
  }) async {
    final userResult = _store.requireUser();
    if (userResult case Failed(:final failure)) return Failed(failure);
    final list = _store.suggestions[roomId] ?? [];
    final item = list.where((s) => s.id == suggestionId).firstOrNull;
    if (item == null) {
      return const Failed(NotFoundFailure('Restaurant not found.'));
    }
    if (item.suggestedBy != userResult.dataOrNull!.id &&
        _store.rooms[roomId]?.hostId != userResult.dataOrNull!.id) {
      return const Failed(PermissionFailure());
    }
    _store.suggestions[roomId] =
        list.where((s) => s.id != suggestionId).toList();
    _store.emitSuggestions(roomId);
    return const Success(null);
  }

  @override
  Future<Result<List<RestaurantSuggestion>>> getSuggestions(String roomId) async {
    return Success(List.unmodifiable(_store.suggestions[roomId] ?? []));
  }

  @override
  Stream<List<RestaurantSuggestion>> watchSuggestions(String roomId) =>
      _store.watchSuggestions(roomId);
}
