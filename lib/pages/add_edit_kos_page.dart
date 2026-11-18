import 'package:flutter/material.dart';
import '../models/kos_model.dart';
import '../services/kos_service.dart';

class AddEditKosPage extends StatefulWidget {
  const AddEditKosPage({super.key, this.kosToEdit});

  final KosModel? kosToEdit;

  @override
  State<AddEditKosPage> createState() => _AddEditKosPageState();
}

class _AddEditKosPageState extends State<AddEditKosPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _addressC = TextEditingController();
  final _priceC = TextEditingController();
  final _facilitiesC = TextEditingController();
  final _descC = TextEditingController();
  final _exteriorUrlC = TextEditingController();
  final _interiorUrlC = TextEditingController();
  final _whatsappC = TextEditingController();
  bool _loading = false;

  bool get isEditing => widget.kosToEdit != null;

  final List<Map<String, String>> _presetExteriorPhotos = [
    {
      'label': 'Gedung Modern',
      'url': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kos Minimalis',
      'url': 'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kos Asri Bali',
      'url': 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Pondok Kampus',
      'url': 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80',
    },
  ];

  final List<Map<String, String>> _presetInteriorPhotos = [
    {
      'label': 'Kamar AC & Springbed',
      'url': 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kamar Tidur Bersih',
      'url': 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kamar & Meja Belajar',
      'url': 'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80',
    },
    {
      'label': 'Kamar Kos Executive',
      'url': 'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final k = widget.kosToEdit!;
      _nameC.text = k.name;
      _addressC.text = k.address;
      _priceC.text = k.price.toString();
      _facilitiesC.text = k.facilities;
      _descC.text = k.description;
      _exteriorUrlC.text = k.exteriorImageUrl ?? '';
      _interiorUrlC.text = k.interiorImageUrl ?? '';
      _whatsappC.text = k.ownerWhatsapp ?? '';
    } else {
      _facilitiesC.text = 'WiFi, Kamar Mandi Dalam, Kasur, Lemari';
      _exteriorUrlC.text = _presetExteriorPhotos[0]['url']!;
      _interiorUrlC.text = _presetInteriorPhotos[0]['url']!;
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _addressC.dispose();
    _priceC.dispose();
    _facilitiesC.dispose();
    _descC.dispose();
    _exteriorUrlC.dispose();
    _interiorUrlC.dispose();
    _whatsappC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final name = _nameC.text.trim();
    final address = _addressC.text.trim();
    final price = int.tryParse(_priceC.text.trim()) ?? 0;
    final facilities = _facilitiesC.text.trim();
    final description = _descC.text.trim();
    final extUrl = _exteriorUrlC.text.trim();
    final intUrl = _interiorUrlC.text.trim();
    final whatsapp = _whatsappC.text.trim().replaceAll(RegExp(r'\s|-|\+'), '');

    bool success = false;
    if (isEditing) {
      success = await KosService.instance.update(widget.kosToEdit!.id, {
        'name': name,
        'address': address,
        'price': price,
        'facilities': facilities,
        'description': description,
        'exterior_image_url': extUrl.isEmpty ? null : extUrl,
        'interior_image_url': intUrl.isEmpty ? null : intUrl,
        'owner_whatsapp': whatsapp.isEmpty ? null : whatsapp,
      });
    } else {
      success = await KosService.instance.add(
        name: name,
        address: address,
        price: price,
        facilities: facilities,
        description: description,
        exteriorImageUrl: extUrl.isEmpty ? null : extUrl,
        interiorImageUrl: intUrl.isEmpty ? null : intUrl,
        ownerWhatsapp: whatsapp.isEmpty ? null : whatsapp,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Informasi kos berhasil diperbarui!' : 'Kos baru berhasil ditambahkan!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operasi ditolak oleh Row Level Security (Bukan pemilik kos)!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ubah Informasi Kos' : 'Tambah Kos Baru'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Bagian Foto Kos (Tampak Luar & Tampak Dalam)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_library, color: Colors.indigo.shade800),
                          const SizedBox(width: 8),
                          const Text(
                            'Foto Kos (Tampak Luar & Tampak Dalam)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Calon penyewa ingin melihat tampilan gedung tampak luar dan kenyamanan kamar tampak dalam.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),

                      // Preview Foto Bersebelahan
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoPreview(
                              title: 'Tampak Luar (Gedung)',
                              url: _exteriorUrlC.text,
                              icon: Icons.apartment,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPhotoPreview(
                              title: 'Tampak Dalam (Kamar)',
                              url: _interiorUrlC.text,
                              icon: Icons.bedroom_parent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Input URL Tampak Luar
                      TextFormField(
                        controller: _exteriorUrlC,
                        decoration: InputDecoration(
                          labelText: 'URL Foto Tampak Luar (Eksterior)',
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.photo_camera_back),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      const Text('Pilih Cepat Foto Tampak Luar:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _presetExteriorPhotos.map((preset) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(preset['label']!, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() => _exteriorUrlC.text = preset['url']!);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 20),

                      // Input URL Tampak Dalam
                      TextFormField(
                        controller: _interiorUrlC,
                        decoration: InputDecoration(
                          labelText: 'URL Foto Tampak Dalam (Interior / Kamar)',
                          hintText: 'https://...',
                          prefixIcon: const Icon(Icons.bed),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 6),
                      const Text('Pilih Cepat Foto Tampak Dalam:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _presetInteriorPhotos.map((preset) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ActionChip(
                                label: Text(preset['label']!, style: const TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() => _interiorUrlC.text = preset['url']!);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Informasi Properti
                TextFormField(
                  controller: _nameC,
                  decoration: InputDecoration(
                    labelText: 'Nama Kos *',
                    hintText: 'Contoh: Kos Graha Harmoni',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nama kos wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressC,
                  decoration: InputDecoration(
                    labelText: 'Alamat / Lokasi *',
                    hintText: 'Contoh: Jl. Udayana No. 10, Singaraja',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceC,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Harga Sewa per Bulan (Rp) *',
                    hintText: 'Contoh: 750000',
                    prefixIcon: const Icon(Icons.payments_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Harga sewa wajib diisi';
                    final n = int.tryParse(v.trim());
                    if (n == null || n <= 0) return 'Harga harus berupa angka lebih dari 0';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _facilitiesC,
                  decoration: InputDecoration(
                    labelText: 'Fasilitas (Pisahkan dengan koma)',
                    hintText: 'WiFi, AC, Kasur, Kamar Mandi Dalam',
                    prefixIcon: const Icon(Icons.check_circle_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descC,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Tambahan',
                    hintText: 'Jelaskan peraturan kos, jarak ke kampus, jam malam, dll...',
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Nomor WhatsApp Pemilik
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.whatsapp, color: Colors.green.shade700, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Kontak WhatsApp Pemilik',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pencari kos akan menghubungi Anda via WhatsApp. Isi dengan nomor aktif.',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _whatsappC,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Nomor WhatsApp (tanpa tanda + atau spasi)',
                          hintText: 'Contoh: 6281234567890',
                          prefixIcon: Icon(Icons.phone_outlined, color: Colors.green.shade600),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // Opsional
                          final clean = v.trim().replaceAll(RegExp(r'\s|-|\+'), '');
                          if (!RegExp(r'^[0-9]{10,15}$').hasMatch(clean)) {
                            return 'Format tidak valid. Gunakan: 6281234567890';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isEditing ? 'Simpan Perubahan' : 'Terbitkan Kos',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview({
    required String title,
    required String url,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade400),
          ),
          clipBehavior: Clip.antiAlias,
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: Colors.grey),
                        const Text('Gagal memuat', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: Icon(icon, color: Colors.grey.shade400, size: 36),
                ),
        ),
      ],
    );
  }
}
