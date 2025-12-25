import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SectionExpandArgs {
  const SectionExpandArgs({
    required this.key,
    required this.defaultExpanded,
  });

  final String key; // e.g. "dashboard.monthly_trend"
  final bool defaultExpanded;
}

final sectionExpandedProvider = AsyncNotifierProviderFamily<
    SectionExpandedController, bool, SectionExpandArgs>(
  SectionExpandedController.new,
);

class SectionExpandedController
    extends FamilyAsyncNotifier<bool, SectionExpandArgs> {
  late SharedPreferences _sp;

  @override
  Future<bool> build(SectionExpandArgs arg) async {
    _sp = await SharedPreferences.getInstance();
    // ✅ if no saved value → use config default
    return _sp.getBool(arg.key) ?? arg.defaultExpanded;
  }

  Future<void> setExpanded(bool v) async {
    state = AsyncData(v);
    await _sp.setBool(arg.key, v);
  }

  Future<void> toggle() async {
    final current = state.value ?? arg.defaultExpanded;
    final next = !current;
    state = AsyncData(next);
    await _sp.setBool(arg.key, next);
  }
}
