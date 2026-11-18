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
  bool _loading = false;

  bool get isEditing => widget.kosToEdit != null;

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
    } else {
      _facilitiesC.text = 'WiFi, Kamar Mandi Dalam, Kasur, Lemari';
    }
  }

  @override
  void dispose() {
    _nameC.dispose();
    _addressC.dispose();
    _priceC.dispose();
    _facilitiesC.dispose();
    _descC.dispose();
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

    bool success = false;
    if (isEditing) {
      success = await KosService.instance.update(widget.kosToEdit!.id, {
        'name': name,
        'address': address,
        'price': price,
        'facilities': facilities,
        'description': description,
      });
    } else {
      success = await KosService.instance.add(
        name: name,
        address: address,
        price: price,
        facilities: facilities,
        description: description,
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
}
