import 'package:cloud_firestore/cloud_firestore.dart';

String? asStringOrTimestamp(dynamic v) {
  if (v == null) return null;
  if (v is String) return v;
  if (v is Timestamp) return v.toDate().toIso8601String();
  return v.toString();
}
