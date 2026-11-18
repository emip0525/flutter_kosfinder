import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _LocalUser {
  final String id;
  final String email;
  final String password;
  final String name;
  final String role;

  _LocalUser({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      };

  factory _LocalUser.fromMap(Map<String, dynamic> m) => _LocalUser(
        id: m['id']?.toString() ?? '',
        email: m['email']?.toString() ?? '',
        password: m['password']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        role: m['role']?.toString() ?? 'seeker',
      );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const String _usersStorageKey = 'kosfinder_registered_users_v2';
  bool _usersLoaded = false;

  static final List<_LocalUser> _defaultUsers = [
    _LocalUser(
      id: 'seeker_uuid_001',
      email: 'pencari@kosfinder.com',
      password: 'seeker123',
      name: 'Miftah (Pencari Kos)',
      role: 'seeker',
    ),
    _LocalUser(
      id: 'owner_a_uuid_001',
      email: 'owner@contoh.com',
      password: 'owner123',
      name: 'I Made Suartana (Owner A)',
      role: 'owner',
    ),
    _LocalUser(
      id: 'owner_b_uuid_002',
      email: 'owner2@contoh.com',
      password: 'owner123',
      name: 'Ni Ketut Ayu (Owner B)',
      role: 'owner',
    ),
    _LocalUser(
      id: 'admin_uuid_001',
      email: 'admin@contoh.com',
      password: 'admin123',
      name: 'Administrator KosFinder',
      role: 'admin',
    ),
  ];

  final List<_LocalUser> _registeredUsers = [];

  Future<void> _ensureUsersLoaded() async {
    if (_usersLoaded) return;
    _registeredUsers.clear();
    _registeredUsers.addAll(_defaultUsers);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_usersStorageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        for (var item in decoded) {
          final u = _LocalUser.fromMap(Map<String, dynamic>.from(item));
          if (!_registeredUsers.any((existing) => existing.email.toLowerCase() == u.email.toLowerCase())) {
            _registeredUsers.add(u);
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Info load users: $e');
    }
    _usersLoaded = true;
  }

  Future<void> _saveUsersToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _registeredUsers.map((u) => u.toMap()).toList();
      await prefs.setString(_usersStorageKey, jsonEncode(listMap));
    } catch (e) {
      debugPrint('[AuthService] Info simpan users: $e');
    }
  }

  // Session state
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

  /// Register user baru dengan validasi ketat
  Future<AuthResponse> register({
    required String email,
    required String password,
    String name = '',
    String role = 'seeker', // 'seeker' atau 'owner'
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    await _ensureUsersLoaded();

    // 1. Cek apakah email sudah terdaftar
    final alreadyExists = _registeredUsers.any((u) => u.email.toLowerCase() == cleanEmail);
    if (alreadyExists) {
      throw const AuthException('Email ini sudah terdaftar! Silakan login langsung menggunakan email tersebut.');
    }

    // 2. Coba registrasi ke Supabase backend jika online
    try {
      final res = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {'name': name, 'role': role},
      ).timeout(const Duration(milliseconds: 1200));

      if (res.user != null) {
        _mockUser = res.user;
        _mockSession = res.session;
      }
    } catch (e) {
      debugPrint('[AuthService.register] Supabase offline/fallback: $e');
    }

    // 3. Simpan akun ke database lokal persisten
    final newUser = _LocalUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      password: password,
      name: name.isNotEmpty ? name : 'Pengguna Baru',
      role: role,
    );
    _registeredUsers.add(newUser);
    await _saveUsersToStorage();

    final user = User(
      id: newUser.id,
      appMetadata: {},
      userMetadata: {'name': newUser.name, 'role': newUser.role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: cleanEmail,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'token_${newUser.id}',
      tokenType: 'bearer',
      user: user,
    );

    debugPrint('[AuthService.register] Akun baru berhasil didaftarkan: $cleanEmail ($role)');
    return AuthResponse(session: _mockSession, user: user);
  }

  /// Login user dengan validasi ketat: akun sembarangan / belum terdaftar DITOLAK
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    await _ensureUsersLoaded();

    // 1. Cek ke Supabase jika tersedia
    try {
      final res = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      ).timeout(const Duration(milliseconds: 1200));

      if (res.user != null) {
        _mockUser = res.user;
        _mockSession = res.session;
        return res;
      }
    } catch (e) {
      debugPrint('[AuthService.login] Supabase offline/fallback: $e');
    }

    // 2. Validasi Akun: Cek apakah email terdaftar di database
    final matchedUser = _registeredUsers.where((u) => u.email.toLowerCase() == cleanEmail).firstOrNull;

    if (matchedUser == null) {
      // Ditolak: Belum terdaftar!
      debugPrint('[AuthService.login] Ditolak: Email $cleanEmail belum terdaftar.');
      throw const AuthException('Akun belum terdaftar! Anda belum memiliki akun, silakan lakukan Register terlebih dahulu.');
    }

    // 3. Validasi Password
    if (matchedUser.password != password) {
      debugPrint('[AuthService.login] Ditolak: Password salah untuk $cleanEmail.');
      throw const AuthException('Password yang Anda masukkan salah! Periksa kembali password Anda.');
    }

    // 4. Login Berhasil
    final user = User(
      id: matchedUser.id,
      appMetadata: {},
      userMetadata: {'name': matchedUser.name, 'role': matchedUser.role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: cleanEmail,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'token_${matchedUser.id}',
      tokenType: 'bearer',
      user: user,
    );

    debugPrint('[AuthService.login] Login berhasil: $cleanEmail sebagai ${matchedUser.role}');
    return AuthResponse(session: _mockSession, user: user);
  }

  /// Pintasan Login Langsung berdasarkan Role (Pencari Kos, Pemilik Kos, Admin)
  Future<void> loginAsRole(String role) async {
    await _ensureUsersLoaded();
    _LocalUser target;
    if (role == 'admin') {
      target = _registeredUsers.firstWhere((u) => u.role == 'admin', orElse: () => _defaultUsers[3]);
    } else if (role == 'owner') {
      target = _registeredUsers.firstWhere((u) => u.role == 'owner', orElse: () => _defaultUsers[1]);
    } else {
      target = _registeredUsers.firstWhere((u) => u.role == 'seeker', orElse: () => _defaultUsers[0]);
    }

    final user = User(
      id: target.id,
      appMetadata: {},
      userMetadata: {'name': target.name, 'role': target.role},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: target.email,
    );
    _mockUser = user;
    _mockSession = Session(
      accessToken: 'token_${target.id}',
      tokenType: 'bearer',
      user: user,
    );
    debugPrint('[AuthService] Login cepat sebagai role: $role (${target.email})');
  }

  /// Logout dan hapus session pengguna
  Future<void> logout() async {
    try {
      await _client.auth.signOut().timeout(const Duration(milliseconds: 800));
    } catch (_) {}
    _mockUser = null;
    _mockSession = null;
  }
}
