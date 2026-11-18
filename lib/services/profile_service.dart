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
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromMap(data);
      }
    } catch (e) {
      debugPrint('[ProfileService.getMyProfile] Supabase query failed: $e');
    }

    // Fallback from auth metadata if profiles table is empty or offline
    final meta = user.userMetadata ?? {};
    final role = meta['role']?.toString() ??
        (user.email?.contains('owner') == true
            ? 'owner'
            : (user.email?.contains('admin') == true ? 'admin' : 'seeker'));
    final name = meta['name']?.toString() ??
        (user.email != null ? user.email!.split('@').first : 'Pengguna KosFinder');

    return UserProfile(
      id: user.id,
      email: user.email ?? 'user@kosfinder.local',
      name: name.isEmpty ? (user.email ?? 'Pengguna') : name,
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
