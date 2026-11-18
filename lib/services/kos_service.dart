import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kos_model.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class KosService {
  KosService._();
  static final KosService instance = KosService._();

  SupabaseClient get _client => Supabase.instance.client;

  String get _currentUid => AuthService.instance.currentUser?.id ?? '';

  // Local state cache for seamless offline / demo mode
  final List<KosModel> _localKosList = [
    KosModel(
      id: 'kos-001',
      ownerId: 'owner_a_uuid_001',
      name: 'Kos Graha Undiksha Asri',
      address: 'Jl. Udayana No. 11, Singaraja, Bali',
      price: 850000,
      facilities: 'WiFi Cepat, AC, Kamar Mandi Dalam, Kasur Springbed, Lemari',
      description: 'Kos nyaman dan strategis khusus mahasiswa. 3 menit jalan kaki ke Kampus Tengah Undiksha. Lingkungan tenang, aman dengan CCTV 24 jam.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      ownerName: 'I Made Suartana (Owner A)',
      isVerified: true,
    ),
    KosModel(
      id: 'kos-002',
      ownerId: 'owner_a_uuid_001',
      name: 'Kos Melati Harmoni',
      address: 'Jl. Ahmad Yani Gg. Remaja No. 4, Singaraja',
      price: 650000,
      facilities: 'WiFi, Kamar Mandi Dalam, Kasur, Parkir Motor Luas',
      description: 'Kos bersih, sirkulasi udara baik, dekat pusat kuliner dan minimarket. Bebas jam malam sopan.',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ownerName: 'I Made Suartana (Owner A)',
      isVerified: false,
    ),
    KosModel(
      id: 'kos-003',
      ownerId: 'owner_b_uuid_002',
      name: 'Kos Bintang Timur Executive',
      address: 'Jl. Dewi Sartika No. 88, Singaraja, Bali',
      price: 1200000,
      facilities: 'AC Daikin, Smart TV, WiFi 100Mbps, Water Heater, Dapur Bersama',
      description: 'Kos eksklusif bernuansa modern minimalis. Sangat cocok bagi mahasiswa tingkat akhir, dosen, maupun profesional muda.',
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      ownerName: 'Ni Ketut Ayu (Owner B)',
      isVerified: true,
    ),
    KosModel(
      id: 'kos-004',
      ownerId: 'owner_b_uuid_002',
      name: 'Pondok Sejahtera Kampus',
      address: 'Jl. Bisma No. 14, Singaraja',
      price: 550000,
      facilities: 'WiFi Gratis, Kasur Busa, Lemari Pakaian, Dapur Umum',
      description: 'Pilihan hemat untuk mahasiswa baru. Lokasi dekat gerbang barat kampus, fasilitas lengkap dan bersih.',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ownerName: 'Ni Ketut Ayu (Owner B)',
      isVerified: false,
    ),
  ];

  /// Mengambil semua kos (Katalog Publik untuk Seeker, Owner, & Admin)
  Future<List<KosModel>> fetchAll() async {
    try {
      final data = await _client
          .from('kos')
          .select()
          .order('created_at', ascending: false);
      if (data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data)
            .map((m) => KosModel.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint('[KosService.fetchAll] Supabase error/offline: $e');
    }
    return List<KosModel>.from(_localKosList);
  }

  /// Mengambil kos yang hanya dimiliki oleh user yang sedang login (Fitur My Kos Owner)
  Future<List<KosModel>> fetchMyKos() async {
    final uid = _currentUid;
    try {
      final data = await _client
          .from('kos')
          .select()
          .eq('owner_id', uid)
          .order('created_at', ascending: false);
      if (data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data)
            .map((m) => KosModel.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint('[KosService.fetchMyKos] Supabase error/offline: $e');
    }
    return _localKosList.where((k) => k.ownerId == uid).toList();
  }

  /// Mengambil kos berdasarkan ID (Detail Kos)
  Future<KosModel?> getById(String id) async {
    try {
      final data = await _client.from('kos').select().eq('id', id).maybeSingle();
      if (data != null) {
        return KosModel.fromMap(data);
      }
    } catch (_) {}
    try {
      return _localKosList.firstWhere((k) => k.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fitur Pencarian untuk Pencari Kos (Seeker)
  Future<List<KosModel>> search({
    String query = '',
    int? maxPrice,
    String? facilityFilter,
  }) async {
    final all = await fetchAll();
    final q = query.toLowerCase().trim();

    return all.where((kos) {
      final matchesQuery = q.isEmpty ||
          kos.name.toLowerCase().contains(q) ||
          kos.address.toLowerCase().contains(q) ||
          kos.description.toLowerCase().contains(q);

      final matchesPrice = maxPrice == null || kos.price <= maxPrice;

      final matchesFacility = facilityFilter == null ||
          facilityFilter.isEmpty ||
          kos.facilities.toLowerCase().contains(facilityFilter.toLowerCase());

      return matchesQuery && matchesPrice && matchesFacility;
    }).toList();
  }

  /// Menambahkan kos baru (Hanya untuk Owner & Admin)
  Future<bool> add({
    required String name,
    required String address,
    required int price,
    String facilities = 'WiFi, Kamar Mandi Dalam',
    String description = '',
  }) async {
    final uid = _currentUid;
    final user = AuthService.instance.currentUser;
    final profile = await ProfileService.instance.getMyProfile();

    // Validasi otorisasi di sisi aplikasi sebelum ke backend
    if (profile != null && profile.isSeeker) {
      debugPrint('[KosService.add] Ditolak: Seeker tidak memiliki izin menambah kos.');
      return false;
    }

    try {
      await _client.from('kos').insert({
        'owner_id': uid,
        'name': name,
        'address': address,
        'price': price,
        'facilities': facilities,
        'description': description,
      });
    } catch (e) {
      debugPrint('[KosService.add] Supabase error: $e');
    }

    // Update local cache
    final newKos = KosModel(
      id: 'kos-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: uid,
      name: name,
      address: address,
      price: price,
      facilities: facilities,
      description: description,
      createdAt: DateTime.now(),
      ownerName: profile?.name ?? user?.email ?? 'Pemilik',
      isVerified: profile?.isAdmin ?? false,
    );
    _localKosList.insert(0, newKos);
    return true;
  }

  /// Mengubah data kos (Hanya pemilik kos atau admin - Dilindungi RLS)
  Future<bool> update(String id, Map<String, dynamic> values) async {
    final uid = _currentUid;
    final profile = await ProfileService.instance.getMyProfile();

    try {
      final rows = await _client.from('kos').update(values).eq('id', id).select();
      if (rows.isNotEmpty) {
        _syncLocalUpdate(id, values);
        return true;
      }
    } catch (e) {
      debugPrint('[KosService.update] Supabase error: $e');
    }

    // RLS Enforcement Simulator for Demo & Security Test:
    final index = _localKosList.indexWhere((k) => k.id == id);
    if (index == -1) return false;

    final target = _localKosList[index];

    // Cek apakah user adalah pemilik asli atau admin
    final isOwnerOfKos = target.ownerId == uid;
    final isAdmin = profile?.isAdmin ?? false;

    if (!isOwnerOfKos && !isAdmin) {
      // ACCESS DENIED OLEH ATURAN ROW LEVEL SECURITY
      debugPrint('[RLS DENIED] User $uid mencoba mengubah Kos milik ${target.ownerId}');
      return false;
    }

    _syncLocalUpdate(id, values);
    return true;
  }

  void _syncLocalUpdate(String id, Map<String, dynamic> values) {
    final index = _localKosList.indexWhere((k) => k.id == id);
    if (index != -1) {
      final old = _localKosList[index];
      _localKosList[index] = old.copyWith(
        name: values['name']?.toString() ?? old.name,
        address: values['address']?.toString() ?? old.address,
        price: values['price'] != null
            ? int.tryParse(values['price'].toString()) ?? old.price
            : old.price,
        facilities: values['facilities']?.toString() ?? old.facilities,
        description: values['description']?.toString() ?? old.description,
        isVerified: values['is_verified'] != null ? values['is_verified'] == true : old.isVerified,
      );
    }
  }

  /// Fitur Admin: Verifikasi Kos
  Future<bool> toggleVerification(String id) async {
    final index = _localKosList.indexWhere((k) => k.id == id);
    if (index == -1) return false;
    final target = _localKosList[index];
    final newStatus = !target.isVerified;
    return update(id, {'is_verified': newStatus});
  }

  /// Menghapus kos (Hanya pemilik kos atau admin - Dilindungi RLS)
  Future<bool> delete(String id) async {
    final uid = _currentUid;
    final profile = await ProfileService.instance.getMyProfile();

    try {
      final rows = await _client.from('kos').delete().eq('id', id).select();
      if (rows.isNotEmpty) {
        _localKosList.removeWhere((k) => k.id == id);
        return true;
      }
    } catch (e) {
      debugPrint('[KosService.delete] Supabase error: $e');
    }

    // RLS Enforcement Simulator:
    final target = _localKosList.where((k) => k.id == id).firstOrNull;
    if (target == null) return false;

    final isOwnerOfKos = target.ownerId == uid;
    final isAdmin = profile?.isAdmin ?? false;

    if (!isOwnerOfKos && !isAdmin) {
      // ACCESS DENIED OLEH ATURAN ROW LEVEL SECURITY
      debugPrint('[RLS DENIED] User $uid mencoba menghapus Kos milik ${target.ownerId}');
      return false;
    }

    _localKosList.removeWhere((k) => k.id == id);
    return true;
  }
}
