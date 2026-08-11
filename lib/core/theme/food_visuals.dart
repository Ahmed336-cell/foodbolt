import 'package:flutter/material.dart';

import '../constants/food_categories.dart';

/// Maps a restaurant name/category to a playful emoji + gradient so every
/// restaurant card and race lane looks distinct without remote images.
class FoodVisuals {
  FoodVisuals._();

  static const _palettes = <List<Color>>[
    [Color(0xFFFF9A3C), Color(0xFFE85D04)],
    [Color(0xFF52B788), Color(0xFF2D6A4F)],
    [Color(0xFF64B5F6), Color(0xFF1976D2)],
    [Color(0xFFBA68C8), Color(0xFF7B1FA2)],
    [Color(0xFFFFD166), Color(0xFFEF8354)],
    [Color(0xFFFF8FA3), Color(0xFFC9184A)],
  ];

  static const _keywordEmojis = <String, String>{
    'burger': '🍔',
    'pizza': '🍕',
    'chicken': '🍗',
    'fried': '🍗',
    'kfc': '🍗',
    'taco': '🌮',
    'mexican': '🌮',
    'sushi': '🍣',
    'japanese': '🍣',
    'asian': '🍜',
    'noodle': '🍜',
    'ramen': '🍜',
    'pasta': '🍝',
    'italian': '🍝',
    'shawarma': '🌯',
    'wrap': '🌯',
    'grill': '🥙',
    'kebab': '🥙',
    'sea': '🦐',
    'fish': '🐟',
    'salad': '🥗',
    'healthy': '🥗',
    'breakfast': '🥞',
    'dessert': '🍰',
    'cake': '🍰',
    'sweet': '🍩',
    'donut': '🍩',
    'coffee': '☕',
    'drink': '🥤',
    'juice': '🧃',
    'ice': '🍦',
    'steak': '🥩',
    'meat': '🥩',
    'rice': '🍚',
    'koshary': '🍚',
    'sandwich': '🥪',
    'hot dog': '🌭',
    'fries': '🍟',
  };

  static String emojiFor({required String name, String? category}) {
    final picked = FoodCategory.byId(category);
    if (picked != null && picked.id != 'other') return picked.emoji;

    final haystack = '${category ?? ''} $name'.toLowerCase();
    for (final entry in _keywordEmojis.entries) {
      if (haystack.contains(entry.key)) return entry.value;
    }
    const fallbacks = ['🍔', '🍕', '🍗', '🌮', '🍜', '🥙'];
    return fallbacks[_seed(name) % fallbacks.length];
  }

  static List<Color> gradientFor(String seedSource) {
    return _palettes[_seed(seedSource) % _palettes.length];
  }

  static Color colorFor(String seedSource) => gradientFor(seedSource).last;

  static int _seed(String value) {
    var hash = 0;
    for (final code in value.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return hash;
  }
}

class FoodBadge extends StatelessWidget {
  const FoodBadge({
    super.key,
    required this.name,
    this.category,
    this.size = 52,
  });

  final String name;
  final String? category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = FoodVisuals.gradientFor(name);
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        FoodVisuals.emojiFor(name: name, category: category),
        style: TextStyle(fontSize: size * 0.5),
      ),
    );
  }
}
