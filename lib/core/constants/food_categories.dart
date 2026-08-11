import 'package:flutter/material.dart';
import 'package:foodbolt/l10n/app_localizations.dart';

/// A fixed catalogue of food categories so suggestions are picked from a list
/// (with an icon) instead of free text. The stored value is always [id].
class FoodCategory {
  const FoodCategory(this.id, this.emoji, this.icon);

  final String id;
  final String emoji;
  final IconData icon;

  String label(AppLocalizations l10n) => switch (id) {
        'burger' => l10n.catBurger,
        'pizza' => l10n.catPizza,
        'chicken' => l10n.catChicken,
        'shawarma' => l10n.catShawarma,
        'grill' => l10n.catGrill,
        'seafood' => l10n.catSeafood,
        'asian' => l10n.catAsian,
        'pasta' => l10n.catPasta,
        'sushi' => l10n.catSushi,
        'mexican' => l10n.catMexican,
        'koshary' => l10n.catKoshary,
        'sandwich' => l10n.catSandwich,
        'breakfast' => l10n.catBreakfast,
        'salad' => l10n.catSalad,
        'dessert' => l10n.catDessert,
        'drinks' => l10n.catDrinks,
        _ => l10n.catOther,
      };

  static const all = <FoodCategory>[
    FoodCategory('burger', '🍔', Icons.lunch_dining),
    FoodCategory('pizza', '🍕', Icons.local_pizza),
    FoodCategory('chicken', '🍗', Icons.egg_alt),
    FoodCategory('shawarma', '🌯', Icons.kebab_dining),
    FoodCategory('grill', '🥩', Icons.outdoor_grill),
    FoodCategory('seafood', '🦐', Icons.set_meal),
    FoodCategory('asian', '🍜', Icons.ramen_dining),
    FoodCategory('pasta', '🍝', Icons.dinner_dining),
    FoodCategory('sushi', '🍣', Icons.rice_bowl),
    FoodCategory('mexican', '🌮', Icons.local_fire_department),
    FoodCategory('koshary', '🍚', Icons.soup_kitchen),
    FoodCategory('sandwich', '🥪', Icons.bakery_dining),
    FoodCategory('breakfast', '🥞', Icons.free_breakfast),
    FoodCategory('salad', '🥗', Icons.eco),
    FoodCategory('dessert', '🍰', Icons.cake),
    FoodCategory('drinks', '🥤', Icons.local_cafe),
    FoodCategory('other', '🍽️', Icons.restaurant),
  ];

  static FoodCategory? byId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Localized label for a stored category id. Falls back to the raw value so
  /// legacy free-text categories still render.
  static String labelOf(AppLocalizations l10n, String? id) {
    final category = byId(id);
    if (category != null) return category.label(l10n);
    return id ?? '';
  }
}
