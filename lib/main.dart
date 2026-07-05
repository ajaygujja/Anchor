import 'package:anchor/app/app.dart';
import 'package:anchor/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Set at build time: `flutter run --dart-define=USE_EMULATORS=true`.
/// When true, Auth and Firestore point at the local Emulator Suite instead of
/// the real project, so day-to-day development never touches production data.
const _useEmulators = bool.fromEnvironment('USE_EMULATORS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (_useEmulators) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }

  // Optimistic, tap-and-forget check-ins depend on local writes surviving an
  // offline gap and syncing when the network returns (spec §4).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const AnchorApp());
}
