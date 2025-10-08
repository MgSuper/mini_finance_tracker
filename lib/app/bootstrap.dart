import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(
    Future<Widget> Function(ProviderContainer) builder) async {
  WidgetsFlutterBinding.ensureInitialized();

  // You can initialize crashlytics, prefs, etc. here (sync things)
  final container = ProviderContainer();
  FlutterError.onError = (details) {
    // You can log with container.read(loggerProvider) if you add one
    FlutterError.presentError(details);
  };

  runApp(UncontrolledProviderScope(
    container: container,
    child: await builder(container),
  ));
}
