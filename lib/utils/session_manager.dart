import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/enter_pin_screen.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager(GlobalKey<NavigatorState> navKey) {
    _instance.navigatorKey = navKey;
    return _instance;
  }
  SessionManager._internal();

  DateTime? _lastPausedTime;
  final Duration timeout = const Duration(minutes: 1);
  GlobalKey<NavigatorState>? navigatorKey;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Debug log
    debugPrint('=== APP STATE: $state ===');

    if (state == AppLifecycleState.paused) {
      // Record when we went into background
      _lastPausedTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed) {
      // If we were backgrounded longer than `timeout`, lock the app
      if (_lastPausedTime != null &&
          DateTime.now().difference(_lastPausedTime!) > timeout) {
        navigatorKey?.currentState?.push(
          MaterialPageRoute(builder: (_) => const EnterPinScreen()),
        );
      }
    }
  }
}
