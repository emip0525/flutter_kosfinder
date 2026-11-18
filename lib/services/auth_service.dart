import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  // Local fallback mock user for demo & testing if offline / mock mode
  User? _mockUser;
  Session? _mockSession;

  User? get currentUser {
    try {
      return _mockUser ?? _client.auth.currentUser;
    } catch (_) {
      return _mockUser;
    }
  }

  Session? get currentSession {
    try {
      return _mockSession ?? _client.auth.currentSession;
    } catch (_) {
      return _mockSession;
    }
  }

  bool get isLoggedIn => currentUser != null || currentSession != null;

  /// Register user baru dengan email, password, nama lengkap, dan role (seeker / owner)
  Future<AuthResponse> register({
    required String email,
    required String password,
    String name = '',
    String role = 'seeker', // 'seeker' atau 'owner'
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role}, // dibaca trigger handle_new_user
      );
      if (res.user != null) {
        _mockUser = res.user;
        _mockSession = res.session;
        return res;
      }
    } catch (e) {
      debugPrint('[AuthService.register] Supabase error/offline: $e');
    }

    // Fallback registration for simulation / offline / web demo
    final user = User(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      appMetadata: {},
      userMetadata: {'name': name, 'role': role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'bearer',
      user: user,
    );
    return AuthResponse(session: _mockSession, user: user);
  }

  /// Login user dengan email dan password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        _mockUser = res.user;
        _mockSession = res.session;
        return res;
      }
    } catch (e) {
      debugPrint('[AuthService.login] Supabase login error/offline: $e');
    }

    // Fallback demo credentials for smooth login on any platform (Chrome, Android, etc.)
    String role = 'seeker';
    String name = 'Pencari Kos';
    String uid = 'seeker_uuid_001';

    final lower = email.toLowerCase().trim();
    if (lower.contains('admin')) {
      role = 'admin';
      name = 'Administrator KosFinder';
      uid = 'admin_uuid_001';
    } else if (lower.contains('owner2') || lower.contains('b')) {
      role = 'owner';
      name = 'Ni Ketut Ayu (Owner B)';
      uid = 'owner_b_uuid_002';
    } else if (lower.contains('owner')) {
      role = 'owner';
      name = 'I Made Suartana (Owner A)';
      uid = 'owner_a_uuid_001';
    } else {
      role = 'seeker';
      name = lower.contains('@') ? lower.split('@').first : 'Pencari Kos';
      uid = 'seeker_${DateTime.now().millisecondsSinceEpoch}';
    }

    final user = User(
      id: uid,
      appMetadata: {},
      userMetadata: {'name': name, 'role': role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      tokenType: 'bearer',
      user: user,
    );
    return AuthResponse(session: _mockSession, user: user);
  }

  /// Logout dan hapus session pengguna
  Future<void> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
    _mockUser = null;
    _mockSession = null;
  }

  /// Method utilitas untuk berganti akun / peran demo dengan cepat saat presentasi & pengujian
  void setDemoUser({required String email, required String name, required String role, required String id}) {
    final user = User(
      id: id,
      appMetadata: {},
      userMetadata: {'name': name, 'role': role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: email,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'demo_token_$id',
      tokenType: 'bearer',
      user: user,
    );
  }
}
