import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role; // seeker | owner | admin

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isSeeker => role == 'seeker';
  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
        id: m['id']?.toString() ?? '',
        email: (m['email'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        role: (m['role'] ?? 'seeker') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
      };
}

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile?> getMyProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(milliseconds: 1000));

      if (data != null) {
        return UserProfile.fromMap(data);
      }
    } catch (e) {
      debugPrint('[ProfileService.getMyProfile] Supabase query offline/fallback: $e');
    }

    // Fallback from auth metadata if profiles table is empty or offline
    final meta = user.userMetadata ?? {};
    final email = user.email ?? '';
    final role = meta['role']?.toString() ??
        (email.contains('admin')
            ? 'admin'
            : (email.contains('owner') ? 'owner' : 'seeker'));
    final name = meta['name']?.toString() ??
        (email.contains('admin')
            ? 'Administrator KosFinder'
            : (email.contains('owner') ? 'Pemilik Kos' : 'Pencari Kos'));

    return UserProfile(
      id: user.id,
      email: email.isEmpty ? 'user@kosfinder.local' : email,
      name: name,
      role: role,
    );
  }

  /// Update role pengguna (misal dari menu admin atau testing)
  Future<bool> updateRole(String userId, String newRole) async {
    try {
      await _client.from('profiles').update({'role': newRole}).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('[ProfileService.updateRole] Error: $e');
      return false;
    }
  }
}
