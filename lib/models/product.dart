/// Product model for read-only listing and detail in agent app
class Product {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String categoryName;
  final double sellingPrice;
  final double? costPrice;
  final double? dailyRate;
  final String? imageUrl;
  final String? brand;
  final bool isActive;

  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.sellingPrice,
    this.costPrice,
    this.dailyRate,
    this.imageUrl,
    this.brand,
    this.isActive = true,
  });

  String get displayImage => imageUrl ?? '';

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // API may return display_image, image_url, or image
    final imageUrl = json['display_image'] ?? json['image_url'] ?? json['image'];
    final url = imageUrl is String ? imageUrl : null;
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      categoryId: json['category'] ?? json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      sellingPrice: _parseDouble(json['selling_price']),
      costPrice: json['cost_price'] != null ? _parseDouble(json['cost_price']) : null,
      dailyRate: json['daily_rate'] != null ? _parseDouble(json['daily_rate']) : null,
      imageUrl: url,
      brand: json['brand'] is String ? json['brand'] as String? : null,
      isActive: json['is_active'] ?? true,
    );
  }
}
