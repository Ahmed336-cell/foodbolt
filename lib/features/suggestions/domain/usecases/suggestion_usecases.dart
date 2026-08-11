import '../../../../core/usecase/usecase.dart';
import '../entities/restaurant_suggestion.dart';
import '../repositories/suggestion_repository.dart';

class AddRestaurantSuggestion
    extends UseCase<RestaurantSuggestion, AddSuggestionParams> {
  AddRestaurantSuggestion(this._repo);
  final SuggestionRepository _repo;

  @override
  Future<Result<RestaurantSuggestion>> call(AddSuggestionParams params) =>
      _repo.addSuggestion(
        roomId: params.roomId,
        name: params.name,
        category: params.category,
        note: params.note,
      );
}

class AddSuggestionParams {
  const AddSuggestionParams({
    required this.roomId,
    required this.name,
    this.category,
    this.note,
  });
  final String roomId;
  final String name;
  final String? category;
  final String? note;
}

class RemoveRestaurantSuggestion extends UseCase<void, RemoveSuggestionParams> {
  RemoveRestaurantSuggestion(this._repo);
  final SuggestionRepository _repo;

  @override
  Future<Result<void>> call(RemoveSuggestionParams params) =>
      _repo.removeSuggestion(
        roomId: params.roomId,
        suggestionId: params.suggestionId,
      );
}

class RemoveSuggestionParams {
  const RemoveSuggestionParams({
    required this.roomId,
    required this.suggestionId,
  });
  final String roomId;
  final String suggestionId;
}
