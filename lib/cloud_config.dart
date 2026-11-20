import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi cloud opsional; fitur kamera/GPS/draft tetap berjalan tanpa ini.
class CloudConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get enabled {
    try {
      if (url.isNotEmpty && publishableKey.isNotEmpty) return true;
      return Supabase.instance.client.auth.currentSession != null ||
          Supabase.instance.client.rest.headers.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
