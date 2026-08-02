import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open Library needs no key, so builds no longer require the dart-define.
  // Restore alongside the Google Books path if its corpus recovers (#75).
  // assert(
  //   const String.fromEnvironment('GOOGLE_BOOKS_API_KEY').isNotEmpty,
  //   'Missing Google Books API key — run with --dart-define-from-file=.env',
  // );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const ProviderScope(child: BookShelfApp()));
}

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookedex',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A3728)),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}
