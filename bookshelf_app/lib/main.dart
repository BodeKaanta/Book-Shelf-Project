import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'screens/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Google Books is the primary source again (#81) and its key is required —
  // keyless calls return 429. Debug-only: this assert is stripped in release, so
  // a keyless release build fails silently. Verify before shipping a bundle.
  assert(
    const String.fromEnvironment('GOOGLE_BOOKS_API_KEY').isNotEmpty,
    'Missing Google Books API key — run with --dart-define-from-file=.env',
  );
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
        // Sampled from assets/icon/bookedex_icon.png — the same red as the
        // Android adaptive background and background_color_ios. fidelity keeps
        // the palette on the seed; the default tonalSpot builds low-chroma
        // pastels, which turned this red into a brown.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEA3442),
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        ),
        useMaterial3: true,
      ),
      home: const MainScaffold(),
    );
  }
}
