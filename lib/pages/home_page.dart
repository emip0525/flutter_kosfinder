import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/kos_model.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/role_guard.dart';
import 'add_edit_kos_page.dart';
import 'admin_panel_page.dart';
import 'kos_detail_page.dart';
import 'login_page.dart';
import 'search_kos_page.dart';
import 'security_test_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserProfile? _profile;
  List<KosModel> _kosList = [];
  bool _loading = true;
  String _activeTab = 'all'; // 'all' | 'my'
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.instance.init();
      await NotificationService.instance.setupInteractedMessage();
      final token = await NotificationService.instance.getToken();
      if (mounted) setState(() => _fcmToken = token);
    });
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final p = await ProfileService.instance.getMyProfile();
    final items = _activeTab == 'my'
        ? await KosService.instance.fetchMyKos()
        : await KosService.instance.fetchAll();

    if (mounted) {
      setState(() {
        _profile = p;
        _kosList = items;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _switchTab(String tab) {
    setState(() => _activeTab = tab);
    _loadData();
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buffer.write(s[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  void _testPushNotification() {
    NotificationService.instance.simulateNotification(
      title: 'KosFinder 🏠',
      body: 'Kos baru tersedia di sekitar kampus! Klik untuk melihat detail.',
      kosId: _kosList.isNotEmpty ? _kosList.first.id : 'kos-001',
    );
  }

  void _copyTokenToClipboard() {
    if (_fcmToken == null) return;
    Clipboard.setData(ClipboardData(text: _fcmToken!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FCM Token berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteKos(KosModel kos) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kos?'),
        content: Text('Apakah Anda yakin ingin menghapus "${kos.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await KosService.instance.delete(kos.id);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kos berhasil dihapus.'), backgroundColor: Colors.green),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Ditolak: Anda bukan pemilik kos ini! (Dilindungi RLS)'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = _profile?.role ?? 'seeker';
    final myId = AuthService.instance.currentUser?.id;
    final isOwnerOrAdmin = role == 'owner' || role == 'admin';
    final isAdmin = role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KosFinder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Role: ${role.toUpperCase()}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isAdmin
                    ? Colors.purple
                    : (role == 'owner' ? Colors.teal : Colors.indigo),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari Kos (Pencari Kos)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchKosPage()),
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Colors.purple),
              tooltip: 'Buka Panel Admin & Notifikasi Siaran',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                );
                _loadData();
              },
            ),
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Kirim Test Push Notification',
            onPressed: _testPushNotification,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. Profil Pengguna Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: isAdmin
                              ? Colors.purple.shade100
                              : (role == 'owner' ? Colors.teal.shade100 : Colors.indigo.shade100),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : (role == 'owner' ? Icons.home_work : Icons.person_search),
                            size: 32,
                            color: isAdmin
                                ? Colors.purple.shade800
                                : (role == 'owner' ? Colors.teal.shade800 : Colors.indigo.shade800),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _profile?.name ?? 'Memuat...',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _profile?.email ?? '-',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? Colors.purple.shade50
                                      : (role == 'owner' ? Colors.teal.shade50 : Colors.indigo.shade50),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isAdmin
                                        ? Colors.purple.shade300
                                        : (role == 'owner' ? Colors.teal.shade300 : Colors.indigo.shade300),
                                  ),
                                ),
                                child: Text(
                                  'Peran: ${role.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isAdmin
                                        ? Colors.purple.shade800
                                        : (role == 'owner' ? Colors.teal.shade800 : Colors.indigo.shade800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    // Shortcut Akses Cepat & Security Test & Admin Panel
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SecurityTestPage()),
                            );
                          },
                          icon: const Icon(Icons.shield_outlined, size: 16),
                          label: const Text('Security Test RLS', style: TextStyle(fontSize: 12)),
                        ),
                        if (isAdmin)
                          FilledButton.icon(
                            style: FilledButton.styleFrom(backgroundColor: Colors.purple.shade700),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                              );
                              _loadData();
                            },
                            icon: const Icon(Icons.admin_panel_settings, size: 16),
                            label: const Text('Kelola Data & Notifikasi', style: TextStyle(fontSize: 12)),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: _testPushNotification,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Test Notif FCM', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 2. Banner FCM Token Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.token, size: 20, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FCM Registration Token:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        Text(
                          _fcmToken != null
                              ? '${_fcmToken!.substring(0, 24)}... (Aktif)'
                              : 'Mengambil token perangkat...',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Salin Token FCM',
                    onPressed: _copyTokenToClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Tab Filter (Khusus Pemilik Kos / Admin)
            if (isOwnerOrAdmin)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Semua Kos'),
                        selected: _activeTab == 'all',
                        onSelected: (val) {
                          if (val) _switchTab('all');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Kos Milik Saya'),
                        selected: _activeTab == 'my',
                        onSelected: (val) {
                          if (val) _switchTab('my');
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Header Daftar Kos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _activeTab == 'my' ? 'Kos Milik Saya' : 'Daftar Kos Tersedia',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_kosList.length} properti',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // 5. Daftar Kos Card List
            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_kosList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.home_work_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _activeTab == 'my'
                            ? 'Anda belum memiliki kos terdaftar. Klik tombol Tambah Kos untuk mempublikasikan.'
                            : 'Belum ada data kos yang tersedia.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._kosList.map((kos) {
                final isMine = kos.ownerId == myId;
                final canModify = isMine || isAdmin;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1.5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => KosDetailPage(kosId: kos.id, initialKos: kos),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: Colors.indigo.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  kos.effectiveExteriorImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.apartment_rounded, color: Colors.indigo.shade700, size: 30),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            kos.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ),
                                        if (kos.isVerified)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: Colors.green),
                                            ),
                                            child: const Text(
                                              'VERIFIED ✓',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      kos.address,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCurrency(kos.price),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo.shade900,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text('/ bulan', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Fasilitas: ${kos.facilities}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (canModify) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isAdmin && !isMine ? Colors.purple.shade50 : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isAdmin && !isMine ? 'ADMIN OVERRIDE' : 'KOS MILIK ANDA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isAdmin && !isMine ? Colors.purple.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () async {
                                    final res = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddEditKosPage(kosToEdit: kos),
                                      ),
                                    );
                                    if (res == true) _loadData();
                                  },
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                ),
                                TextButton.icon(
                                  onPressed: () => _deleteKos(kos),
                                  icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                  label: const Text('Hapus', style: TextStyle(fontSize: 12, color: Colors.red)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: 60),
          ],
        ),
      ),
      // RoleGuard: Tombol Tambah Kos hanya muncul untuk Owner dan Admin (Praktik 4)
      floatingActionButton: RoleGuard(
        role: role,
        allowed: const ['owner', 'admin'],
        child: FloatingActionButton.extended(
          onPressed: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddEditKosPage()),
            );
            if (res == true) _loadData();
          },
          icon: const Icon(Icons.add_home),
          label: const Text('Tambah Kos'),
        ),
      ),
    );
  }
}
