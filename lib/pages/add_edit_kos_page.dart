import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/kos_model.dart';
import '../services/device_location_service.dart';
import '../services/draft_repository.dart';
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

  final _picker = ImagePicker();
  final _draftRepo = DraftRepository();
  final _locationService = DeviceLocationService();

  bool _loading = false;
  bool _gettingLocation = false;
  bool _pickingPhoto = false;

  bool get isEditing => widget.kosToEdit != null;

  final List<Map<String, String>> _presetExteriorPhotos = [
    {
      'label': 'Gedung Modern',
      'url':
          'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Kos Minimalis',
      'url':
          'https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Kos Asri Bali',
      'url':
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Pondok Kampus',
      'url':
          'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?auto=format&fit=crop&w=800&q=80'
    },
  ];

  final List<Map<String, String>> _presetInteriorPhotos = [
    {
      'label': 'Kamar AC & Springbed',
      'url':
          'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Kamar Tidur Bersih',
      'url':
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Kamar & Meja Belajar',
      'url':
          'https://images.unsplash.com/photo-1595526114035-0d45ed16cfbf?auto=format&fit=crop&w=800&q=80'
    },
    {
      'label': 'Kamar Kos Executive',
      'url':
          'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?auto=format&fit=crop&w=800&q=80'
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

  // ---------- Permission helpers ----------
  Future<bool> _requestMediaPermission(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    return status.isGranted;
  }

  Future<bool> _requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  // ---------- Foto Picker ----------
  Future<void> _pickPhoto(
      {required bool isExterior, required ImageSource source}) async {
    if (!await _requestMediaPermission(source)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin kamera/galeri ditolak.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _pickingPhoto = true);
    try {
      final selected =
          await _picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
      if (selected == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Pemilihan foto dibatalkan; foto sebelumnya tetap.'),
            behavior: SnackBarBehavior.floating));
        return;
      }
      final permanentPath = await _draftRepo.savePermanentPhoto(selected);
      if (!mounted) return;
      setState(() {
        if (isExterior) {
          _exteriorUrlC.text = permanentPath;
        } else {
          _interiorUrlC.text = permanentPath;
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Foto ${isExterior ? "eksterior" : "kamar"} berhasil diambil.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  // ---------- GPS ----------
  Future<void> _getCurrentLocation() async {
    if (!await _requestLocationPermission()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Izin lokasi ditolak.'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _gettingLocation = true);
    try {
      final position = await _locationService.getPosition();
      final lat = position.latitude.toStringAsFixed(6);
      final lng = position.longitude.toStringAsFixed(6);
      if (!mounted) return;
      setState(() {
        final existing = _addressC.text.trim();
        if (existing.isEmpty) {
          _addressC.text = 'Lokasi GPS: Lat $lat, Long $lng';
        } else {
          final clean = existing.replaceAll(RegExp(r'\s*\(GPS:.*?\)'), '');
          _addressC.text = '$clean (GPS: $lat, $lng)';
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Koordinat GPS berhasil: $lat, $lng'),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
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
    final whatsapp =
        _whatsappC.text.trim().replaceAll(RegExp(r'\s|-|\+'), '');

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isEditing
              ? 'Informasi kos berhasil diperbarui!'
              : 'Kos baru berhasil ditambahkan!'),
          backgroundColor: Colors.green.shade700));
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Operasi ditolak oleh Row Level Security (Bukan pemilik kos)!'),
          backgroundColor: Colors.red));
    }
  }

  Widget _buildPhotoPreview(
      {required String title, required String url, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
                const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400)),
          clipBehavior: Clip.antiAlias,
          child: url.isNotEmpty
              ? (url.startsWith('http')
                  ? Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: Colors.grey),
                              const Text('Gagal memuat',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey))
                            ],
                          )))
                  : Image.file(File(url),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Center(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: Colors.grey),
                              const Text('Gagal memuat',
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey))
                            ],
                          ))))
              : Center(
                  child: Icon(icon, color: Colors.grey.shade400, size: 36)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(isEditing ? 'Ubah Informasi Kos' : 'Tambah Kos Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Photo section ----
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.indigo.shade200)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.photo_camera,
                              color: Colors.indigo.shade800),
                          const SizedBox(width: 8),
                          const Expanded(
                              child: Text(
                                  'Foto Kos (Kamera, Galeri & URL)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                          'Anda dapat memotret langsung dengan Kamera HP, memilih dari Galeri, atau memasukkan link URL foto.',
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPhotoPreview(
                                title: 'Tampak Luar (Gedung)',
                                url: _exteriorUrlC.text,
                                icon: Icons.apartment),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildPhotoPreview(
                                title: 'Tampak Dalam (Kamar)',
                                url: _interiorUrlC.text,
                                icon: Icons.bedroom_parent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text('Foto Tampak Luar (Eksterior):',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickingPhoto
                                  ? null
                                  : () => _pickPhoto(
                                      isExterior: true,
                                      source: ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Kamera',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickingPhoto
                                  ? null
                                  : () => _pickPhoto(
                                      isExterior: true,
                                      source: ImageSource.gallery),
                              icon:
                                  const Icon(Icons.photo_library, size: 16),
                              label: const Text('Galeri',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _exteriorUrlC,
                        decoration: InputDecoration(
                            labelText: 'Path File atau Link URL Tampak Luar',
                            hintText: 'Hasil kamera/galeri atau https://...',
                            prefixIcon:
                                const Icon(Icons.link, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _presetExteriorPhotos
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                        label: Text(p['label']!),
                                        onPressed: () => setState(
                                            () => _exteriorUrlC.text =
                                                p['url']!)),
                                  ))
                              .toList(),
                        ),
                      ),
                      const Divider(height: 24),
                      const Text('Foto Tampak Dalam (Interior / Kamar):',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickingPhoto
                                  ? null
                                  : () => _pickPhoto(
                                      isExterior: false,
                                      source: ImageSource.camera),
                              icon: const Icon(Icons.camera_alt, size: 16),
                              label: const Text('Kamera',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: _pickingPhoto
                                  ? null
                                  : () => _pickPhoto(
                                      isExterior: false,
                                      source: ImageSource.gallery),
                              icon:
                                  const Icon(Icons.photo_library, size: 16),
                              label: const Text('Galeri',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _interiorUrlC,
                        decoration: InputDecoration(
                            labelText: 'Path File atau Link URL Kamar',
                            hintText: 'Hasil kamera/galeri atau https://...',
                            prefixIcon:
                                const Icon(Icons.link, size: 20),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.white,
                            isDense: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _presetInteriorPhotos
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                        label: Text(p['label']!),
                                        onPressed: () => setState(
                                            () => _interiorUrlC.text =
                                                p['url']!)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ---- Nama ----
                TextFormField(
                  controller: _nameC,
                  decoration: const InputDecoration(
                      labelText: 'Nama Kos *',
                      hintText: 'Contoh: Kos Graha Harmoni',
                      prefixIcon: Icon(Icons.home_outlined),
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama kos wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                // ---- Alamat & GPS ----
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alamat / Lokasi Kos *',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        TextButton.icon(
                          onPressed: _gettingLocation
                              ? null
                              : _getCurrentLocation,
                          icon: _gettingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.my_location,
                                  size: 16, color: Colors.teal),
                          label: Text(
                              _gettingLocation
                                  ? 'Mencari GPS...'
                                  : 'Ambil dari GPS',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressC,
                      decoration: const InputDecoration(
                          labelText: 'Alamat Lengkap',
                          hintText: 'Jl. Contoh No.1, Kota',
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Alamat wajib diisi'
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // ---- Harga ----
                TextFormField(
                  controller: _priceC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      hintText: 'contoh: 1500000',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder()),
                  validator: (v) =>
                      (v != null && v.trim().isNotEmpty && int.tryParse(v.trim()) == null)
                          ? 'Harga harus berupa angka'
                          : null,
                ),
                const SizedBox(height: 14),
                // ---- Fasilitas ----
                TextFormField(
                  controller: _facilitiesC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Fasilitas *',
                      hintText: 'Contoh: WiFi, AC, Dapur',
                      prefixIcon: Icon(Icons.room_service),
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Fasilitas wajib diisi'
                      : null,
                ),
                const SizedBox(height: 14),
                // ---- Deskripsi ----
                TextFormField(
                  controller: _descC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Deskripsi *',
                      hintText: 'Deskripsikan kos secara singkat',
                      prefixIcon: Icon(Icons.notes),
                      border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Deskripsi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 24),
                // ---- WhatsApp ----
                const Text('Kontak WhatsApp Pemilik',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green)),
                const SizedBox(height: 4),
                const Text(
                    'Pencari kos akan menghubungi Anda via WhatsApp. Isi dengan nomor aktif.',
                    style:
                        TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _whatsappC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      labelText: 'Nomor WhatsApp (tanpa + atau spasi)',
                      hintText: 'Contoh: 6281234567890',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final clean =
                        v.trim().replaceAll(RegExp(r'\s|-|\+'), '');
                    if (!RegExp(r'^[0-9]{10,15}$').hasMatch(clean))
                      return 'Format tidak valid. Gunakan: 6281234567890';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(
                      isEditing ? 'Simpan Perubahan' : 'Terbitkan Kos'),
                  style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
