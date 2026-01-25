import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

/// Read-only product detail. No status, visibility, or sales summary.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final api = ApiService();
    final res = await api.getProduct(widget.product.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) _product = res.data;
      });
    }
  }

  String _imageUrl(Product p) {
    final url = p.displayImage;
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/$'), '');
    final path = url.startsWith('/') ? url : '/$url';
    return '$base$path';
  }

  @override
  Widget build(BuildContext context) {
    final p = _product ?? widget.product;
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final imageUrl = _imageUrl(p);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image
                  Container(
                    color: Colors.white,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholder(),
                            )
                          : _placeholder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Info card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.categoryName,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        if (p.brand != null && p.brand!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            p.brand!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textHint,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          currencyFormat.format(p.sellingPrice),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (p.dailyRate != null && p.dailyRate! > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            'From ${currencyFormat.format(p.dailyRate)} / day',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                        if (p.description != null && p.description!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p.description!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppTheme.dividerColor,
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.textHint),
      ),
    );
  }
}
