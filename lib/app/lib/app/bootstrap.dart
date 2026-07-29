import 'package:firebase_core/firebase_core.dart';

import '../core/firebase/firebase_options.dart';
import 'app.dart';

Future<void> bootstrap() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Futuras inicializações:
  // FirebaseCrashlytics
  // FirebaseAnalytics
  // Remote Config
  // Notification Service
}
