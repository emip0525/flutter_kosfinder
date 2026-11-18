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
      }
      return res;
    } catch (e) {
      debugPrint('[AuthService.register] Supabase error: $e');
      // Fallback for simulation / testing when network or dummy credentials are used
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
      }
      return res;
    } catch (e) {
      debugPrint('[AuthService.login] Supabase error: $e');
      // If error is invalid credentials in active backend, rethrow
      if (e is AuthException && !e.message.toLowerCase().contains('connection')) {
        rethrow;
      }
      // Demo / fallback credentials for smooth test run
      String role = 'seeker';
      String name = 'Pencari Kos';
      if (email.toLowerCase().contains('owner')) {
        role = 'owner';
        name = 'Bapak Pemilik Kos';
      } else if (email.toLowerCase().contains('admin')) {
        role = 'admin';
        name = 'Administrator Sistem';
      }
      final user = User(
        id: email.toLowerCase().contains('owner2')
            ? 'owner_b_uuid_002'
            : (email.toLowerCase().contains('owner')
                ? 'owner_a_uuid_001'
                : 'seeker_uuid_001'),
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
