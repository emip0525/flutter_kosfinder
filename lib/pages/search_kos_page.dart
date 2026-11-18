import 'package:flutter/material.dart';
import '../models/kos_model.dart';
import '../services/kos_service.dart';
import 'kos_detail_page.dart';

class SearchKosPage extends StatefulWidget {
  const SearchKosPage({super.key});

  @override
  State<SearchKosPage> createState() => _SearchKosPageState();
}

class _SearchKosPageState extends State<SearchKosPage> {
  final _searchController = TextEditingController();
  List<KosModel> _results = [];
  bool _loading = false;
  String _selectedFacility = '';
  int? _maxPrice;

  final List<String> _quickFacilities = ['WiFi', 'AC', 'Kamar Mandi', 'Kasur'];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    setState(() => _loading = true);
    final results = await KosService.instance.search(
      query: _searchController.text.trim(),
      maxPrice: _maxPrice,
      facilityFilter: _selectedFacility.isEmpty ? null : _selectedFacility,
    );
    if (mounted) {
      setState(() {
        _results = results;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Kos (Fitur Seeker)'),
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama kos, alamat, atau lokasi kampus...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                const Text('Filter Fasilitas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Semua'),
                        selected: _selectedFacility.isEmpty,
                        onSelected: (val) {
                          setState(() => _selectedFacility = '');
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._quickFacilities.map((fac) {
                        final isSel = _selectedFacility == fac;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(fac),
                            selected: isSel,
                            onSelected: (val) {
                              setState(() => _selectedFacility = val ? fac : '');
                              _performSearch();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Batas Harga Maksimal: ', style: TextStyle(fontSize: 12)),
                    Text(
                      _maxPrice == null ? 'Semua Harga' : _formatCurrency(_maxPrice!),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                  ],
                ),
                Slider(
                  value: (_maxPrice ?? 2000000).toDouble(),
                  min: 400000,
                  max: 2000000,
                  divisions: 16,
                  label: _maxPrice == null ? 'Maksimal' : _formatCurrency(_maxPrice!),
                  onChanged: (val) {
                    setState(() => _maxPrice = val.toInt());
                    _performSearch();
                  },
                ),
              ],
            ),
          ),
          // Results Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ditemukan ${_results.length} kos',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                if (_maxPrice != null || _selectedFacility.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _maxPrice = null;
                        _selectedFacility = '';
                        _searchController.clear();
                      });
                      _performSearch();
                    },
                    child: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          // Results List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada kos yang cocok dengan kriteria pencarian.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (context, i) {
                          final kos = _results[i];
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
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.indigo.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(Icons.home_work, color: Colors.indigo.shade700),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                kos.name,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                kos.address,
                                                style: const TextStyle(color: Colors.black54, fontSize: 13),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          _formatCurrency(kos.price),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo.shade900,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Fasilitas: ${kos.facilities}',
                                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
