import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_keys.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase Cloud Messaging
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('[Firebase Init] Berjalan dalam mode lokal/simulator: $e');
  }

  // Inisialisasi Supabase Backend
  try {
    await Supabase.initialize(
      url: 'https://znhrqszqchmwbqwbzrqp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpuaHJxc3pxY2htd2Jxd2J6cnFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDk4Mjk1NTgsImV4cCI6MjAyNTQwNTU1OH0.sample_anon_key',
    );
  } catch (e) {
    debugPrint('[Supabase Init] Berjalan dalam mode persistensi lokal: $e');
  }

  // Mendengarkan perubahan session (Auth Event Listener)
  try {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('Auth event: ${data.event}');
      if (data.event == AuthChangeEvent.signedOut) {
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    });
  } catch (_) {}

  runApp(const KosFinderApp());
}

class KosFinderApp extends StatelessWidget {
  const KosFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KosFinder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      // Check Session -> Jika session tersimpan buka HomePage, jika tidak buka LoginPage
      home: AuthService.instance.isLoggedIn
          ? const HomePage()
          : const LoginPage(),
    );
  }
}
