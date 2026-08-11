import '../../../../core/usecase/usecase.dart';
import '../entities/restaurant_suggestion.dart';

abstract class SuggestionRepository {
  Future<Result<RestaurantSuggestion>> addSuggestion({
    required String roomId,
    required String name,
    String? category,
    String? note,
  });
  Future<Result<void>> removeSuggestion({
    required String roomId,
    required String suggestionId,
  });
  Future<Result<List<RestaurantSuggestion>>> getSuggestions(String roomId);
  Stream<List<RestaurantSuggestion>> watchSuggestions(String roomId);
}
