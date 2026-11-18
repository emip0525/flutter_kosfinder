import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kos_model.dart';
import 'auth_service.dart';
import 'profile_service.dart';

class KosService {
  KosService._();
  static final KosService instance = KosService._();

  SupabaseClient get _client => Supabase.instance.client;

  String get _currentUid => AuthService.instance.currentUser?.id ?? '';

  static const String _storageKey = 'kosfinder_kos_list_v2';
  bool _initialized = false;

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
      ownerWhatsapp: '6281234567890',
      exteriorImageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      interiorImageUrl: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
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
      ownerWhatsapp: '6281234567890',
      exteriorImageUrl: 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
      interiorImageUrl: 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=800&q=80',
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
      ownerWhatsapp: '6289876543210',
      exteriorImageUrl: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
      interiorImageUrl: 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=800&q=80',
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
      ownerWhatsapp: '6289876543210',
      exteriorImageUrl: 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
      interiorImageUrl: 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
      isVerified: false,
    ),
  ];

  /// Memastikan data dari memori lokal termuat (Persistensi LocalStorage / SharedPreferences)
  Future<void> _ensureLoaded() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final List decoded = jsonDecode(savedJson);
        _localKosList.clear();
        for (var item in decoded) {
          _localKosList.add(KosModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    } catch (e) {
      debugPrint('[KosService] Info: Menggunakan data awal: $e');
    }
    _initialized = true;
  }

  /// Menyimpan perubahan ke memori permanen agar tidak hilang saat refresh browser (F5)
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = _localKosList.map((k) => k.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(listMap));
    } catch (e) {
      debugPrint('[KosService] Info simpan storage: $e');
    }
  }

  /// Mengambil semua kos (Katalog Publik untuk Seeker, Owner, & Admin)
  Future<List<KosModel>> fetchAll() async {
    await _ensureLoaded();
    try {
      final data = await _client
          .from('kos')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1200));
      if (data.isNotEmpty) {
        final remoteList = List<Map<String, dynamic>>.from(data)
            .map((m) => KosModel.fromMap(m))
            .toList();
        return remoteList;
      }
    } catch (e) {
      debugPrint('[KosService.fetchAll] Menggunakan katalog lokal: $e');
    }
    return List<KosModel>.from(_localKosList);
  }

  /// Mengambil kos yang hanya dimiliki oleh user yang sedang login (Fitur My Kos Owner)
  Future<List<KosModel>> fetchMyKos() async {
    await _ensureLoaded();
    final uid = _currentUid;
    try {
      final data = await _client
          .from('kos')
          .select()
          .eq('owner_id', uid)
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 1200));
      if (data.isNotEmpty) {
        return List<Map<String, dynamic>>.from(data)
            .map((m) => KosModel.fromMap(m))
            .toList();
      }
    } catch (e) {
      debugPrint('[KosService.fetchMyKos] Menggunakan daftar lokal: $e');
    }
    return _localKosList.where((k) => k.ownerId == uid).toList();
  }

  /// Mengambil kos berdasarkan ID (Detail Kos)
  Future<KosModel?> getById(String id) async {
    await _ensureLoaded();
    try {
      final data = await _client
          .from('kos')
          .select()
          .eq('id', id)
          .maybeSingle()
          .timeout(const Duration(milliseconds: 1200));
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
    String? exteriorImageUrl,
    String? interiorImageUrl,
    String? ownerWhatsapp,
  }) async {
    await _ensureLoaded();
    final uid = _currentUid;
    final user = AuthService.instance.currentUser;
    final profile = await ProfileService.instance.getMyProfile();

    final isSeeker = profile?.isSeeker ?? false;
    final isAdmin = (profile?.isAdmin ?? false) ||
        (user?.email?.toLowerCase().contains('admin') ?? false) ||
        (user?.userMetadata?['role'] == 'admin');

    if (isSeeker && !isAdmin) {
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
        'exterior_image_url': exteriorImageUrl,
        'interior_image_url': interiorImageUrl,
        'owner_whatsapp': ownerWhatsapp,
      }).timeout(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('[KosService.add] Supabase insert offline/fallback: $e');
    }

    // Update local cache — selalu tambah ke list lokal & simpan permanen
    final newKos = KosModel(
      id: 'kos-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: uid.isNotEmpty ? uid : 'owner_custom_001',
      name: name,
      address: address,
      price: price,
      facilities: facilities,
      description: description,
      createdAt: DateTime.now(),
      ownerName: profile?.name ?? user?.email ?? 'Pemilik',
      ownerWhatsapp: ownerWhatsapp,
      exteriorImageUrl: exteriorImageUrl ??
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
      interiorImageUrl: interiorImageUrl ??
          'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
      isVerified: isAdmin,
    );

    _localKosList.insert(0, newKos);
    await _saveToStorage();
    debugPrint('[KosService.add] Kos berhasil ditambahkan dan disimpan permanen: ${newKos.name}');
    return true;
  }

  /// Mengubah data kos (Hanya pemilik kos atau admin - Dilindungi RLS)
  Future<bool> update(String id, Map<String, dynamic> values) async {
    await _ensureLoaded();
    final uid = _currentUid;
    final user = AuthService.instance.currentUser;
    final profile = await ProfileService.instance.getMyProfile();

    try {
      await _client
          .from('kos')
          .update(values)
          .eq('id', id)
          .timeout(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('[KosService.update] Supabase update offline/fallback: $e');
    }

    // RLS Enforcement Simulator for Demo & Security Test:
    final index = _localKosList.indexWhere((k) => k.id == id);
    if (index == -1) return false;

    final target = _localKosList[index];

    final isOwnerOfKos = target.ownerId == uid;
    final isAdmin = (profile?.isAdmin ?? false) ||
        (user?.email?.toLowerCase().contains('admin') ?? false) ||
        (user?.userMetadata?['role'] == 'admin');

    if (!isOwnerOfKos && !isAdmin) {
      debugPrint('[RLS DENIED] User $uid mencoba mengubah Kos milik ${target.ownerId}');
      return false;
    }

    _syncLocalUpdate(id, values);
    await _saveToStorage();
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
        exteriorImageUrl: values['exterior_image_url']?.toString() ?? old.exteriorImageUrl,
        interiorImageUrl: values['interior_image_url']?.toString() ?? old.interiorImageUrl,
        ownerWhatsapp: values.containsKey('owner_whatsapp')
            ? values['owner_whatsapp']?.toString()
            : old.ownerWhatsapp,
        isVerified: values['is_verified'] != null ? values['is_verified'] == true : old.isVerified,
      );
    }
  }

  /// Fitur Admin: Verifikasi Kos
  Future<bool> toggleVerification(String id) async {
    await _ensureLoaded();
    final index = _localKosList.indexWhere((k) => k.id == id);
    if (index == -1) return false;
    final target = _localKosList[index];
    final newStatus = !target.isVerified;
    return update(id, {'is_verified': newStatus});
  }

  /// Menghapus kos (Hanya pemilik kos atau admin - Dilindungi RLS)
  Future<bool> delete(String id) async {
    await _ensureLoaded();
    final uid = _currentUid;
    final user = AuthService.instance.currentUser;
    final profile = await ProfileService.instance.getMyProfile();

    try {
      await _client
          .from('kos')
          .delete()
          .eq('id', id)
          .timeout(const Duration(milliseconds: 1500));
    } catch (e) {
      debugPrint('[KosService.delete] Supabase delete offline/fallback: $e');
    }

    // RLS Enforcement Simulator — cek izin di mode offline/demo
    final target = _localKosList.where((k) => k.id == id).firstOrNull;
    if (target == null) return false;

    final isOwnerOfKos = target.ownerId == uid;
    final isAdmin = (profile?.isAdmin ?? false) ||
        (user?.email?.toLowerCase().contains('admin') ?? false) ||
        (user?.userMetadata?['role'] == 'admin');

    debugPrint('[KosService.delete] uid=$uid, ownerId=${target.ownerId}, isOwner=$isOwnerOfKos, isAdmin=$isAdmin');

    if (!isOwnerOfKos && !isAdmin) {
      debugPrint('[RLS DENIED] User $uid mencoba menghapus Kos milik ${target.ownerId}');
      return false;
    }

    _localKosList.removeWhere((k) => k.id == id);
    await _saveToStorage();
    debugPrint('[KosService.delete] Kos $id berhasil dihapus dan diperbarui di storage permanen');
    return true;
  }
}
