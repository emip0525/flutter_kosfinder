import 'package:flutter/material.dart';
import '../models/kos_model.dart';
import '../services/kos_service.dart';
import '../services/notification_service.dart';
import 'add_edit_kos_page.dart';
import 'kos_detail_page.dart';

class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  List<KosModel> _kosList = [];
  bool _loading = true;

  final _customTitleC = TextEditingController();
  final _customBodyC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _customTitleC.dispose();
    _customBodyC.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _loading = true);
    final items = await KosService.instance.fetchAll();
    if (mounted) {
      setState(() {
        _kosList = items;
        _loading = false;
      });
    }
  }

  void _sendNotification({
    required String title,
    required String body,
    String? kosId,
  }) {
    NotificationService.instance.simulateNotification(
      title: title,
      body: body,
      kosId: kosId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notifikasi berhasil disiarkan: "$title"'),
        backgroundColor: Colors.indigo.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleVerify(KosModel kos) async {
    await KosService.instance.toggleVerification(kos.id);
    final newStatus = !kos.isVerified;

    if (newStatus) {
      _sendNotification(
        title: 'KosFinder: Data Kos Terverifikasi ✅',
        body: 'Selamat! Properti "${kos.name}" Anda telah resmi diverifikasi oleh Admin KosFinder.',
        kosId: kos.id,
      );
    }

    _loadAllData();
  }

  Future<void> _deleteKos(KosModel kos) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin: Hapus Kos?'),
        content: Text('Apakah Anda yakin ingin menghapus "${kos.name}" dari sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus (Admin Override)'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await KosService.instance.delete(kos.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kos berhasil dihapus oleh Admin.'), backgroundColor: Colors.green),
      );
      _loadAllData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus: Akses ditolak oleh sistem keamanan.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifiedCount = _kosList.where((k) => k.isVerified).length;
    final unverifiedCount = _kosList.length - verifiedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Pengelolaan Sistem (Admin)'),
        backgroundColor: Colors.purple.shade50,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Ringkasan Statistik Sistem
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total Properti',
                          value: '${_kosList.length}',
                          icon: Icons.domain,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Terverifikasi',
                          value: '$verifiedCount',
                          icon: Icons.verified,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Menunggu',
                          value: '$unverifiedCount',
                          icon: Icons.hourglass_top,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. Pusat Siaran Push Notification (FCM)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.campaign, color: Colors.purple.shade700, size: 26),
                              const SizedBox(width: 8),
                              const Text(
                                'Kirim Informasi & Push Notification',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kirimkan notifikasi massal ke pencari kos atau notifikasi verifikasi ke pemilik kos.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Divider(height: 20),
                          // Preset 1: Kos Baru Tersedia
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: const Icon(Icons.home, color: Colors.indigo),
                            ),
                            title: const Text('“Kos baru tersedia di sekitar kampus”', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Kirim ke semua pencari kos di sekitar kampus', style: TextStyle(fontSize: 12)),
                            trailing: FilledButton.icon(
                              onPressed: () {
                                _sendNotification(
                                  title: 'KosFinder: Kos Baru Tersedia! 🏠',
                                  body: 'Ada beberapa pilihan kos baru di sekitar kampus. Buka sekarang untuk melihat fasilitas dan harganya!',
                                  kosId: _kosList.isNotEmpty ? _kosList.first.id : null,
                                );
                              },
                              icon: const Icon(Icons.send, size: 16),
                              label: const Text('Kirim', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const Divider(height: 16),
                          // Preset 2: Data Kos Berhasil Diverifikasi
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(Icons.verified, color: Colors.green),
                            ),
                            title: const Text('“Data kos Anda berhasil diverifikasi”', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: const Text('Kirim ke pemilik kos setelah verifikasi data', style: TextStyle(fontSize: 12)),
                            trailing: FilledButton.tonalIcon(
                              onPressed: () {
                                _sendNotification(
                                  title: 'KosFinder: Data Kos Terverifikasi ✅',
                                  body: 'Data kos Anda telah berhasil diverifikasi oleh Admin. Iklan kos Anda kini memiliki centang verifikasi resmi.',
                                  kosId: _kosList.isNotEmpty ? _kosList.first.id : null,
                                );
                              },
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Kirim', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const Divider(height: 16),
                          // Custom Broadcast
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            leading: const Icon(Icons.edit_notifications_outlined),
                            title: const Text('Kirim Notifikasi Kustom', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            children: [
                              TextField(
                                controller: _customTitleC,
                                decoration: const InputDecoration(
                                  labelText: 'Judul Pesan',
                                  hintText: 'Misal: Promo Awal Bulan KosFinder',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _customBodyC,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Isi Pesan Notifikasi',
                                  hintText: 'Ketik pesan yang akan diterima di perangkat pengguna...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () {
                                    final title = _customTitleC.text.trim();
                                    final body = _customBodyC.text.trim();
                                    if (title.isEmpty || body.isEmpty) return;
                                    _sendNotification(title: title, body: body);
                                    _customTitleC.clear();
                                    _customBodyC.clear();
                                  },
                                  icon: const Icon(Icons.broadcast_on_personal),
                                  label: const Text('Siarkan Notifikasi ke Seluruh Pengguna'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Hak Akses Lebih Luas: Kelola Seluruh Data Kos Sistem
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kelola Seluruh Properti (Admin Override)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text('${_kosList.length} total', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._kosList.map((kos) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.home_work, color: Colors.purple.shade700, size: 28),
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
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: kos.isVerified ? Colors.green.shade50 : Colors.amber.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: kos.isVerified ? Colors.green : Colors.amber),
                                            ),
                                            child: Text(
                                              kos.isVerified ? 'VERIFIED ✓' : 'UNVERIFIED',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: kos.isVerified ? Colors.green.shade800 : Colors.amber.shade900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Pemilik: ${kos.ownerName ?? kos.ownerId}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                      Text(kos.address, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _toggleVerify(kos),
                                  icon: Icon(
                                    kos.isVerified ? Icons.cancel_outlined : Icons.verified_outlined,
                                    size: 16,
                                    color: kos.isVerified ? Colors.orange : Colors.green,
                                  ),
                                  label: Text(
                                    kos.isVerified ? 'Cabut Verifikasi' : 'Verifikasi Kos',
                                    style: TextStyle(fontSize: 12, color: kos.isVerified ? Colors.orange : Colors.green),
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.visibility, size: 18),
                                  tooltip: 'Lihat Detail',
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => KosDetailPage(kosId: kos.id, initialKos: kos),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18),
                                  tooltip: 'Ubah Data (Admin Override)',
                                  onPressed: () async {
                                    final res = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => AddEditKosPage(kosToEdit: kos),
                                      ),
                                    );
                                    if (res == true) _loadAllData();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                  tooltip: 'Hapus Data (Admin Override)',
                                  onPressed: () => _deleteKos(kos),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.shade700, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color.shade900)),
          Text(title, style: TextStyle(fontSize: 11, color: color.shade800)),
        ],
      ),
    );
  }
}
