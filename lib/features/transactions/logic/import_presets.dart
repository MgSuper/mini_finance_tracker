import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImportPreset {
  ImportPreset({
    required this.name,
    required this.mapping,
    required this.currencyFallback,
  });

  final String name;
  final Map<String, int> mapping;
  final String currencyFallback;

  Map<String, dynamic> toJson() => {
        'name': name,
        'mapping': mapping,
        'currencyFallback': currencyFallback,
      };

  static ImportPreset fromJson(Map<String, dynamic> json) => ImportPreset(
        name: json['name'] as String,
        mapping: (json['mapping'] as Map)
            .map((k, v) => MapEntry(k as String, v as int)),
        currencyFallback: json['currencyFallback'] as String,
      );
}

final importPresetsProvider =
    AsyncNotifierProvider<ImportPresetsController, List<ImportPreset>>(
        ImportPresetsController.new);

class ImportPresetsController extends AsyncNotifier<List<ImportPreset>> {
  static const _k = 'import_presets_v1';

  @override
  Future<List<ImportPreset>> build() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(ImportPreset.fromJson).toList();
  }

  Future<void> savePreset(ImportPreset preset) async {
    final cur = [...(state.value ?? [])];
    final idx = cur.indexWhere((p) => p.name == preset.name);
    if (idx >= 0) {
      cur[idx] = preset;
    } else {
      cur.add(preset);
    }
    state = AsyncData(cur);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, jsonEncode(cur.map((e) => e.toJson()).toList()));
  }

  Future<void> deletePreset(String name) async {
    final cur = [...(state.value ?? [])]..removeWhere((p) => p.name == name);
    state = AsyncData(cur);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, jsonEncode(cur.map((e) => e.toJson()).toList()));
  }
}
