import 'package:flutter/material.dart';
import '../models/kos_model.dart';
import '../services/auth_service.dart';
import '../services/kos_service.dart';
import '../services/profile_service.dart';
import 'add_edit_kos_page.dart';

class KosDetailPage extends StatefulWidget {
  const KosDetailPage({
    super.key,
    required this.kosId,
    this.initialKos,
  });

  final String kosId;
  final KosModel? initialKos;

  @override
  State<KosDetailPage> createState() => _KosDetailPageState();
}

class _KosDetailPageState extends State<KosDetailPage> {
  KosModel? _kos;
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _kos = widget.initialKos;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    _profile = await ProfileService.instance.getMyProfile();
    final item = await KosService.instance.getById(widget.kosId);
    if (mounted) {
      setState(() {
        if (item != null) _kos = item;
        _loading = false;
      });
    }
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

  Future<void> _deleteKos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kos?'),
        content: Text('Apakah Anda yakin ingin menghapus "${_kos?.name}"? Tindakan ini tidak dapat dibatalkan.'),
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

    final success = await KosService.instance.delete(widget.kosId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kos berhasil dihapus.'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
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
    final myId = AuthService.instance.currentUser?.id;
    final isMine = _kos != null && _kos!.ownerId == myId;
    final isAdmin = _profile?.isAdmin ?? false;
    final canModify = isMine || isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Kos'),
        actions: [
          if (canModify && _kos != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Ubah Data Kos',
              onPressed: () async {
                final updated = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => AddEditKosPage(kosToEdit: _kos),
                  ),
                );
                if (updated == true) _loadData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              tooltip: 'Hapus Kos',
              onPressed: _deleteKos,
            ),
          ],
        ],
      ),
      body: _loading && _kos == null
          ? const Center(child: CircularProgressIndicator())
          : _kos == null
              ? const Center(child: Text('Data kos tidak ditemukan.'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Banner Header Image Placeholder
                      Container(
                        height: 220,
                        color: Colors.indigo.shade100,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Icon(Icons.apartment_rounded, size: 100, color: Colors.indigo.shade300),
                            Positioned(
                              bottom: 12,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'ID: ${_kos!.id}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    _kos!.name,
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.indigo.shade200),
                                  ),
                                  child: Text(
                                    '${_formatCurrency(_kos!.price)} / bln',
                                    style: TextStyle(
                                      color: Colors.indigo.shade900,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 18, color: Colors.redAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _kos!.address,
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            const Text(
                              'Fasilitas Tersedia',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _kos!.facilities
                                  .split(',')
                                  .map((f) => Chip(
                                        avatar: const Icon(Icons.check_circle_outline, size: 16, color: Colors.teal),
                                        label: Text(f.trim(), style: const TextStyle(fontSize: 12)),
                                        backgroundColor: Colors.grey.shade100,
                                      ))
                                  .toList(),
                            ),
                            const Divider(height: 32),
                            const Text(
                              'Deskripsi Kos',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _kos!.description.isEmpty
                                  ? 'Pemilik belum menambahkan deskripsi tambahan untuk properti kos ini.'
                                  : _kos!.description,
                              style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                            ),
                            const Divider(height: 32),
                            const Text(
                              'Informasi Kepemilikan (Authorization / RLS)',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Owner ID : ${_kos!.ownerId}', style: const TextStyle(fontSize: 12)),
                                  Text('User ID Anda : ${myId ?? "Belum login"}', style: const TextStyle(fontSize: 12)),
                                  Text(
                                    isMine
                                        ? 'Status : Kos ini adalah MILIK ANDA (Berhak Ubah & Hapus)'
                                        : (isAdmin
                                            ? 'Status : ANDA ADALAH ADMIN (Hak Akses Penuh Sistem)'
                                            : 'Status : Kos milik pengguna lain (Hanya Baca / Read-Only)'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isMine || isAdmin ? Colors.teal.shade800 : Colors.indigo.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Menghubungi pemilik ${_kos!.name}...'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat),
                                label: const Text('Hubungi Pemilik Kos'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
