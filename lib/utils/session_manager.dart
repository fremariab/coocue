import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/enter_pin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager with WidgetsBindingObserver {
  // single instance of session manager
  static final SessionManager _instance = SessionManager._internal();

  // factory to set navigator key and return the same instance
  factory SessionManager(GlobalKey<NavigatorState> navKey) {
    _instance.navigatorKey = navKey;
    return _instance;
  }

  // private constructor for singleton
  SessionManager._internal();

  // last time the app was paused
  DateTime? _lastPausedTime;

  // duration before requiring pin on resume
  final Duration timeout = const Duration(minutes: 1);

  // key to access navigator for push
  GlobalKey<NavigatorState>? navigatorKey;

  // check if current user role is parent
  Future<bool> _isParent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role') == 'parent';
  }

  // listen to app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // record pause time
    if (state == AppLifecycleState.paused) {
      _lastPausedTime = DateTime.now();
    }

    // on resume, if timeout passed and user is parent, ask for pin
    if (state == AppLifecycleState.resumed &&
        _lastPausedTime != null &&
        DateTime.now().difference(_lastPausedTime!) > timeout) {
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
