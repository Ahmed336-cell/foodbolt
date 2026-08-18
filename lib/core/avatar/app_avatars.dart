import 'dart:math';

/// Named avatars stored as a string id (never an image file).
class AppAvatar {
  const AppAvatar({
    required this.id,
    required this.emoji,
    required this.color,
    required this.suggestedName,
  });

  final String id;
  final String emoji;
  final int color;
  final String suggestedName;
}

class AppAvatars {
  AppAvatars._();

  static const defaultId = 'ninja';

  static const all = <AppAvatar>[
    AppAvatar(id: 'ninja', emoji: '🥷', color: 0xFF2B2D42, suggestedName: 'NinjaMan'),
    AppAvatar(id: 'pizza', emoji: '🍕', color: 0xFFE85D04, suggestedName: 'PizzaFox'),
    AppAvatar(id: 'burger', emoji: '🍔', color: 0xFFB08968, suggestedName: 'BurgerBoss'),
    AppAvatar(id: 'taco', emoji: '🌮', color: 0xFFE9C46A, suggestedName: 'TacoNinja'),
    AppAvatar(id: 'sushi', emoji: '🍣', color: 0xFFE76F51, suggestedName: 'SushiSam'),
    AppAvatar(id: 'ramen', emoji: '🍜', color: 0xFFE63946, suggestedName: 'RamenKing'),
    AppAvatar(id: 'chef', emoji: '👨‍🍳', color: 0xFF264653, suggestedName: 'ChefDash'),
    AppAvatar(id: 'fox', emoji: '🦊', color: 0xFFE76F51, suggestedName: 'FoxBite'),
    AppAvatar(id: 'cat', emoji: '🐱', color: 0xFFF4A261, suggestedName: 'CatNoodle'),
    AppAvatar(id: 'robot', emoji: '🤖', color: 0xFF457B9D, suggestedName: 'RoboEats'),
    AppAvatar(id: 'alien', emoji: '👽', color: 0xFF2A9D8F, suggestedName: 'AlienSnack'),
    AppAvatar(id: 'dragon', emoji: '🐲', color: 0xFF2D6A4F, suggestedName: 'DragonBite'),
    AppAvatar(id: 'panda', emoji: '🐼', color: 0xFF6D6875, suggestedName: 'PandaMunch'),
    AppAvatar(id: 'lion', emoji: '🦁', color: 0xFFE9C46A, suggestedName: 'LionGrill'),
    AppAvatar(id: 'penguin', emoji: '🐧', color: 0xFF1D3557, suggestedName: 'PenguinRoll'),
    AppAvatar(id: 'fire', emoji: '🔥', color: 0xFFE85D04, suggestedName: 'FireFork'),
  ];

  static AppAvatar byId(String? id) {
    if (id == null || id.isEmpty) return all.first;
    return all.where((a) => a.id == id).firstOrNull ?? all.first;
  }

  static AppAvatar random([Random? random]) {
    final r = random ?? Random();
    return all[r.nextInt(all.length)];
  }
}
