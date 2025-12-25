import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_finan/features/server_ui/models/ui_config_model.dart';

class UiConfigRepository {
  final FirebaseFirestore db;
  const UiConfigRepository(this.db);

  Stream<UiConfigModel> watchConfig({required String docId}) {
    final doc = db.collection('ui_configs').doc(docId);
    return doc.snapshots().map((s) {
      final data = s.data();
      if (data == null) {
        throw StateError('Missing ui_configs/$docId');
      }
      return UiConfigModel.fromJson(data);
    });
  }
}
