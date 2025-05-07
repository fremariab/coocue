import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coocue/services/cot_audio_service.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:coocue/utils/session_manager.dart';
import 'package:coocue/firebase_options.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // load environment variables from .env file
  await dotenv.load();

  // ensure flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // initialize firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // create a firestore instance for the "coocue" database
  final firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'coocue',
  );

  // read the saved user role from shared preferences
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('role');

  // if the user is the cot and already paired, start the audio service
  if (role == 'cot') {
    final secure = const FlutterSecureStorage();
    final pairId = await secure.read(key: 'pair_id');
    if (pairId != null) {
      await CotAudioService().init(pairId);
      debugPrint('✅ cot audio service initialized for pair $pairId');
    }
  }

  // launch the app
  runApp(const CoocueApp());
}

class CoocueApp extends StatefulWidget {
  const CoocueApp({super.key});

  @override
  State<CoocueApp> createState() => _CoocueAppState();
}

class _CoocueAppState extends State<CoocueApp> {
  // key to manage navigation from anywhere
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // attach session manager to observe app lifecycle
    WidgetsBinding.instance.addObserver(SessionManager(navigatorKey));
  }

  @override
  void dispose() {
    // remove the session manager observer
    WidgetsBinding.instance.removeObserver(SessionManager(navigatorKey));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // set up the material app with splash screen as the home
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
