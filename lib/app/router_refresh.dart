import 'dart:async';
import 'package:flutter/foundation.dart';

/// Minimal replacement for GoRouterRefreshStream from examples.
/// Listens to a stream and notifies the router when it emits.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
