import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_keys.dart';
import '../firebase_options.dart';
import '../pages/kos_detail_page.dart';

/// Background message handler harus top-level function di luar class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('[BACKGROUND] Notification Title: ${message.notification?.title}');
  debugPrint('[BACKGROUND] Notification Body : ${message.notification?.body}');
  debugPrint('[BACKGROUND] Data Payload       : ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;

  FirebaseMessaging get messaging {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  String? _cachedToken;
  String? get cachedToken => _cachedToken;

  /// Meminta izin notifikasi (Praktik 8)
  Future<AuthorizationStatus> requestPermission() async {
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('Notification permission status: ${settings.authorizationStatus.name}');
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('[requestPermission] Error/Unsupported platform: $e');
      return AuthorizationStatus.authorized;
    }
  }

  /// Mendapatkan FCM Token (Praktik 9)
  Future<String?> getToken() async {
    try {
      final token = await messaging.getToken();
      _cachedToken = token;
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('[getToken] Error/Fallback demo token: $e');
      _cachedToken = 'fcm_mock_token_2415051011_kosfinder_ws9_${DateTime.now().millisecondsSinceEpoch}';
      return _cachedToken;
    }
  }

  /// Mendengarkan perubahan FCM token
  void listenTokenRefresh(void Function(String token) onRefresh) {
    try {
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token diperbarui: $newToken');
        _cachedToken = newToken;
        onRefresh(newToken);
      });
    } catch (_) {}
  }

  /// Device Registration: Menyimpan token perangkat ke Supabase (Praktik 9 Opsional)
  Future<void> saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await Supabase.instance.client.from('device_tokens').upsert({
        'token': token,
        'user_id': user.id,
        'platform': defaultTargetPlatform.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('FCM Device Token tersimpan di database Supabase');
    } catch (e) {
      debugPrint('[saveTokenToSupabase] Supabase save error: $e');
    }
  }

  /// Inisialisasi Listener & Handler Notifikasi (Praktik 10)
  Future<void> init() async {
    await requestPermission();
    final token = await getToken();
    if (token != null) {
      await saveTokenToSupabase(token);
    }
    listenTokenRefresh(saveTokenToSupabase);

    try {
      // iOS / macOS presentation options
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    // FOREGROUND: Saat aplikasi sedang aktif dibuka (Praktik 10)
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FOREGROUND] Notification received');
        debugPrint('title: ${message.notification?.title}');
        debugPrint('body : ${message.notification?.body}');
        debugPrint('data : ${message.data}');

        final title = message.notification?.title ?? 'Notifikasi KosFinder';
        final body = message.notification?.body ?? 'Ada informasi baru di sekitar Anda.';

        // Tampilkan in-app banner / SnackBar
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.indigo.shade800,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
            action: message.data['kos_id'] != null
                ? SnackBarAction(
                    label: 'LIHAT',
                    textColor: Colors.amber,
                    onPressed: () {
                      _handleTap(message);
                    },
                  )
                : null,
          ),
        );
      });
    } catch (_) {}
  }

  /// Menangani Interaksi Notifikasi saat Di-tap (Praktik Q - Bonus)
  Future<void> setupInteractedMessage() async {
    try {
      // Kondisi TERMINATED -> dibuka dari klik notifikasi
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _handleTap(initial);
      }

      // Kondisi BACKGROUND -> dibuka dari klik notifikasi
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    } catch (_) {}
  }

  void _handleTap(RemoteMessage message) {
    final kosId = message.data['kos_id'];
    if (kosId == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => KosDetailPage(kosId: kosId.toString()),
      ),
    );
  }

  /// Simulator Push Notification (Praktik 11 Uji Coba Cepat di App)
  void simulateNotification({
    required String title,
    required String body,
    String? kosId,
  }) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.indigo.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amberAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    body,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: kosId != null
            ? SnackBarAction(
                label: 'BUKA KOS',
                textColor: Colors.amberAccent,
                onPressed: () {
                  navigatorKey.currentState?.push(
                    MaterialPageRoute(
                      builder: (_) => KosDetailPage(kosId: kosId),
                    ),
                  );
                },
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
