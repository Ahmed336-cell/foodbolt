import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/saved_order_template.dart';
import '../../domain/repositories/saved_orders_repository.dart';

class SavedOrdersPrefsRepository implements SavedOrdersRepository {
  SavedOrdersPrefsRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _key = 'foodbolt_saved_orders_v1';

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<List<SavedOrderTemplate>> loadAll() async {
    try {
      final prefs = await _ensure();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final list = jsonDecode(raw) as List;
      return [
        for (final e in list)
          SavedOrderTemplate.fromJson(Map<String, dynamic>.from(e as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(SavedOrderTemplate template) async {
    final prefs = await _ensure();
    final current = await loadAll();
    final next = [
      template,
      ...current.where((t) => t.id != template.id),
    ];
    await prefs.setString(
      _key,
      jsonEncode([for (final t in next) t.toJson()]),
    );
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await _ensure();
    final current = await loadAll();
    final next = current.where((t) => t.id != id).toList();
    await prefs.setString(
      _key,
      jsonEncode([for (final t in next) t.toJson()]),
    );
  }
}
