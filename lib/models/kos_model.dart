class KosModel {
  final String id;
  final String ownerId;
  final String name;
  final String address;
  final int price;
  final String facilities;
  final String description;
  final DateTime createdAt;
  final String? ownerName;
  final String? imageUrl;
  final bool isVerified;

  const KosModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.price,
    this.facilities = 'WiFi, Kamar Mandi Dalam',
    this.description = '',
    required this.createdAt,
    this.ownerName,
    this.imageUrl,
    this.isVerified = false,
  });

  factory KosModel.fromMap(Map<String, dynamic> map) {
    return KosModel(
      id: map['id']?.toString() ?? '',
      ownerId: map['owner_id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Kos Tanpa Nama',
      address: map['address']?.toString() ?? 'Alamat belum diatur',
      price: (map['price'] is int)
          ? map['price'] as int
          : int.tryParse(map['price']?.toString() ?? '0') ?? 0,
      facilities: map['facilities']?.toString() ?? 'WiFi, Kasur, Kamar Mandi',
      description: map['description']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      ownerName: map['owner_name']?.toString(),
      imageUrl: map['image_url']?.toString(),
      isVerified: map['is_verified'] == true || map['is_verified'] == 1 || map['is_verified'] == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'price': price,
      'facilities': facilities,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_verified': isVerified,
    };
  }

  KosModel copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? address,
    int? price,
    String? facilities,
    String? description,
    DateTime? createdAt,
    String? ownerName,
    String? imageUrl,
    bool? isVerified,
  }) {
    return KosModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      price: price ?? this.price,
      facilities: facilities ?? this.facilities,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      ownerName: ownerName ?? this.ownerName,
      imageUrl: imageUrl ?? this.imageUrl,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
