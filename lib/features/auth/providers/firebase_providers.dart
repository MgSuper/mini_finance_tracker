import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider((_) => FirebaseAuth.instance);
final firestoreProvider = Provider((_) => FirebaseFirestore.instance);
