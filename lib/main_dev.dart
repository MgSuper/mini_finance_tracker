import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mini_finan/app/app.dart';
import 'package:mini_finan/app/bootstrap.dart';
import 'package:mini_finan/firebase_options_dev.dart';

Future<void> main() async {
  await bootstrap((_) async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await useEmulatorsIfLocal(
        FirebaseAuth.instance, FirebaseFirestore.instance);
    return const FinanceAIApp();
  });
}

Future<void> useEmulatorsIfLocal(
    FirebaseAuth auth, FirebaseFirestore db) async {
  const useEmulator = String.fromEnvironment('USE_EMULATORS') == 'true';

  if (useEmulator) {
    await auth.useAuthEmulator('localhost', 9099);
    db.useFirestoreEmulator('localhost', 8080);
  }
}
