import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/enter_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager with WidgetsBindingObserver {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager(GlobalKey<NavigatorState> navKey) {
    _instance.navigatorKey = navKey; // keep the singleton
    return _instance;
  }
  SessionManager._internal();

  DateTime? _lastPausedTime;
  final Duration timeout = const Duration(minutes: 1);
  GlobalKey<NavigatorState>? navigatorKey;

  // ➊ ───────────── NEW helper ─────────────
  Future<bool> _isParent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') == 'parent';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    }

    if (state == AppLifecycleState.resumed &&
        _lastPausedTime != null &&
        DateTime.now().difference(_lastPausedTime!) > timeout) {
      // ➋ ───────────── Guard it ─────────────
      _isParent().then((parent) {
        if (parent) {
          navigatorKey?.currentState?.push(
            MaterialPageRoute(builder: (_) => const EnterPinScreen()),
          );
        }
      });
    }
  }
}
