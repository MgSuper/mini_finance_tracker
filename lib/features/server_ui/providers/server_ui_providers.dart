import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mini_finan/app/app_env.dart';
import 'package:mini_finan/features/server_ui/data/ui_config_repository.dart';
import 'package:mini_finan/features/server_ui/models/ui_config_model.dart';

final uiConfigRepositoryProvider = Provider<UiConfigRepository>((ref) {
  return UiConfigRepository(FirebaseFirestore.instance);
});

final uiConfigProvider = StreamProvider<UiConfigModel>((ref) {
  final repo = ref.watch(uiConfigRepositoryProvider);
  final docId = AppEnvironment.docId;
  return repo.watchConfig(docId: docId);
});
