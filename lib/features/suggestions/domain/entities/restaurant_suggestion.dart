import 'package:equatable/equatable.dart';

class RestaurantSuggestion extends Equatable {
  const RestaurantSuggestion({
    required this.id,
    required this.roomId,
    required this.name,
    required this.suggestedBy,
    required this.suggestedByName,
    this.category,
    this.note,
    this.imageUrl,
    this.voteCount = 0,
  });

  final String id;
  final String roomId;
  final String name;
  final String suggestedBy;
  final String suggestedByName;
  final String? category;
  final String? note;
  final String? imageUrl;
  final int voteCount;

  RestaurantSuggestion copyWith({int? voteCount}) {
    return RestaurantSuggestion(
      id: id,
      roomId: roomId,
      name: name,
      suggestedBy: suggestedBy,
      suggestedByName: suggestedByName,
      category: category,
      note: note,
      imageUrl: imageUrl,
      voteCount: voteCount ?? this.voteCount,
    );
  }

  @override
  List<Object?> get props =>
      [id, roomId, name, suggestedBy, suggestedByName, category, note, imageUrl, voteCount];
}
