import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:coocue/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:coocue/utils/session_manager.dart';
import 'package:coocue/firebase_options.dart';
void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Create a Firestore instance that talks to your non-default "coocue" database:
  final firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'coocue', // <-- exactly the DB ID from the console
  );
  
  runApp(const CoocueApp());
}

class CoocueApp extends StatefulWidget {
  const CoocueApp({super.key});

  @override
  State<CoocueApp> createState() => _CoocueAppState();
}

class _CoocueAppState extends State<CoocueApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Attach the SessionManager as an observer
    WidgetsBinding.instance.addObserver(SessionManager(navigatorKey));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(SessionManager(navigatorKey));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
