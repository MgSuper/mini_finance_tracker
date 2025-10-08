import 'package:firebase_core/firebase_core.dart';
import 'package:mini_finan/app/app.dart';
import 'package:mini_finan/app/bootstrap.dart';
import 'package:mini_finan/firebase_options_dev.dart';

Future<void> main() async {
  await bootstrap((_) async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    return const FinanceAIApp();
  });
}
