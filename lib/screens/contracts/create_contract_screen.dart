import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/customer.dart';
import '../../models/product.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class CreateContractScreen extends StatefulWidget {
  const CreateContractScreen({super.key});

  @override
  State<CreateContractScreen> createState() => _CreateContractScreenState();
}

class _CreateContractScreenState extends State<CreateContractScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  Customer? _selectedCustomer;
  Product? _selectedProduct;
  final _totalPriceController = TextEditingController();
  String _paymentFrequency = 'DAILY';
  DateTime? _startDate;

  List<Product> _products = [];
  bool _loadingProducts = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  final TextEditingController _productSearchController =
      TextEditingController();
  final TextEditingController _customerSearchController =
      TextEditingController();

  static const List<Map<String, String>> _frequencyOptions = [
    {'value': 'DAILY', 'label': 'Daily'},
    {'value': 'WEEKLY', 'label': 'Weekly'},
    {'value': 'BI_WEEKLY', 'label': 'Bi-Weekly'},
    {'value': 'MONTHLY', 'label': 'Monthly'},
  ];

  static const Map<String, int> _frequencyInstallments = {
    'DAILY': 72,
    'WEEKLY': 12,
    'BI_WEEKLY': 6,
    'MONTHLY': 3,
  };

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _productSearchController.dispose();
    _customerSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    final res = await _api.getProducts(isActive: true);
    if (mounted) {
      setState(() {
        _loadingProducts = false;
        _products = res.success && res.data != null ? res.data! : [];
      });
    }
  }

  void _onProductChanged(Product? product) {
    setState(() {
      _selectedProduct = product;
      if (product != null) {
        _totalPriceController.text = product.sellingPrice.toStringAsFixed(2);
      } else {
        _totalPriceController.clear();
      }
    });
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final minDate = DateTime(now.year, now.month, now.day);
    final initial = (_startDate != null && _startDate!.isAfter(minDate))
        ? _startDate!
        : minDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: minDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer.');
      return;
    }
    if (_selectedProduct == null) {
      setState(() => _errorMessage = 'Please select a product.');
      return;
    }

    final totalPrice = _selectedProduct!.sellingPrice;
    if (totalPrice <= 0) {
      setState(() => _errorMessage = 'Total price must be greater than zero.');
      return;
    }
    if (_startDate == null) {
      setState(() => _errorMessage = 'Please select a start date.');
      return;
    }
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day);
    if (_startDate!.isBefore(minDate)) {
      setState(
        () => _errorMessage = 'Start date cannot be earlier than today.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);

    final res = await _api.createContract(
      customerId: _selectedCustomer!.id,
      productId: _selectedProduct!.id,
      totalPrice: totalPrice,
      paymentFrequency: _paymentFrequency,
      expectedStartDate: startStr,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      final appProvider = context.read<AppProvider>();
      final authProvider = context.read<AuthProvider>();
      await appProvider.loadContracts(
        agentId: authProvider.user?.id,
        forceRefresh: true,
      );
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = res.error ?? 'Failed to create contract.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: 'GHS ',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Contract'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Customer
              const Text(
                'Customer *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildSearchableCustomerField(),
              const SizedBox(height: 20),
              // Product
              const Text(
                'Product *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _loadingProducts
                  ? const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildSearchableProductField(currencyFormat),
              const SizedBox(height: 20),
              // Total price (derived from selected product)
              const Text(
                'Total Price (GHS)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _totalPriceController,
                readOnly: true,
                enabled: false,
                decoration: _inputDecoration().copyWith(
                  hintText: 'Select a product to set price',
                ),
              ),
              const SizedBox(height: 20),
              // Payment frequency
              const Text(
                'Payment Frequency *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentFrequency,
                decoration: _inputDecoration(),
                items: _frequencyOptions
                    .map(
                      (e) => DropdownMenuItem(
                        value: e['value'],
                        child: Text(e['label']!),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _paymentFrequency = v ?? 'DAILY'),
              ),
              const SizedBox(height: 12),
              _buildPaymentBreakdownCard(currencyFormat),
              const SizedBox(height: 20),
              // Start date (end date set to start + 3 months on backend)
              const Text(
                'Start Date *',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Expected end date will be 3 months after start date',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickStartDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Text(
                    _startDate != null
                        ? DateFormat('yyyy-MM-dd').format(_startDate!)
                        : 'Select date',
                    style: TextStyle(
                      color: _startDate != null
                          ? AppTheme.textPrimary
                          : AppTheme.textHint,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create Contract'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableCustomerField() {
    return InkWell(
      onTap: () => _showCustomerSearchDialog(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedCustomer != null
                    ? '${_selectedCustomer!.fullName} - ${_selectedCustomer!.phoneNumber}'
                    : 'Search customer by name or phone',
                style: TextStyle(
                  color: _selectedCustomer != null
                      ? AppTheme.textPrimary
                      : AppTheme.textHint,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.search, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomerSearchDialog() async {
    final appProvider = context.read<AppProvider>();
    final customers = appProvider.customers.where((c) => c.isActive).toList();
    _customerSearchController.clear();
    List<Customer> filteredCustomers = List.from(customers);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void filterCustomers(String query) {
            setDialogState(() {
              if (query.isEmpty) {
                filteredCustomers = List.from(customers);
              } else {
                final lowerQuery = query.toLowerCase();
                filteredCustomers = customers
                    .where(
                      (c) =>
                          c.fullName.toLowerCase().contains(lowerQuery) ||
                          (c.phoneNumber.contains(query)),
                    )
                    .toList();
              }
            });
          }

          return AlertDialog(
            title: const Text('Search Customer'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _customerSearchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone number...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: filterCustomers,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: filteredCustomers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No customers found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredCustomers.length,
                            itemBuilder: (context, index) {
                              final customer = filteredCustomers[index];
                              final isSelected =
                                  _selectedCustomer?.id == customer.id;
                              return ListTile(
                                title: Text(
                                  customer.fullName,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(customer.phoneNumber),
                                selected: isSelected,
                                onTap: () {
                                  setState(() => _selectedCustomer = customer);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchableProductField(NumberFormat currencyFormat) {
    return InkWell(
      onTap: () => _showProductSearchDialog(currencyFormat),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedProduct != null
                    ? '${_selectedProduct!.name} - ${currencyFormat.format(_selectedProduct!.sellingPrice)}'
                    : 'Search and select product',
                style: TextStyle(
                  color: _selectedProduct != null
                      ? AppTheme.textPrimary
                      : AppTheme.textHint,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            Icon(Icons.search, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showProductSearchDialog(NumberFormat currencyFormat) async {
    _productSearchController.clear();
    List<Product> filteredProducts = List.from(_products);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void filterProducts(String query) {
            setDialogState(() {
              if (query.isEmpty) {
                filteredProducts = List.from(_products);
              } else {
                final lowerQuery = query.toLowerCase();
                filteredProducts = _products
                    .where(
                      (p) =>
                          p.name.toLowerCase().contains(lowerQuery) ||
                          p.brand?.toLowerCase().contains(lowerQuery) == true ||
                          p.categoryName.toLowerCase().contains(lowerQuery) ||
                          (p.subcategoryName?.toLowerCase().contains(
                                lowerQuery,
                              ) ==
                              true),
                    )
                    .toList();
              }
            });
          }

          return AlertDialog(
            title: const Text('Search Product'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _productSearchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText:
                          'Search by name, brand, category, or subcategory...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: filterProducts,
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: filteredProducts.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No products found',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              final isSelected =
                                  _selectedProduct?.id == product.id;
                              return ListTile(
                                title: Text(
                                  product.name,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  '${product.subcategoryName != null && product.subcategoryName!.isNotEmpty ? '${product.categoryName} / ${product.subcategoryName}' : product.categoryName}${product.brand != null ? ' - ${product.brand}' : ''}',
                                ),
                                trailing: Text(
                                  currencyFormat.format(product.sellingPrice),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                selected: isSelected,
                                onTap: () {
                                  _onProductChanged(product);
                                  Navigator.of(context).pop();
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentBreakdownCard(NumberFormat currencyFormat) {
    final totalPrice =
        _selectedProduct?.sellingPrice ??
        double.tryParse(_totalPriceController.text) ??
        0;
    if (totalPrice <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3-Month Payment Guide',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expected installment amount for each payment frequency.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '3 months',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._frequencyOptions.map((option) {
            final frequency = option['value']!;
            final installments = _frequencyInstallments[frequency] ?? 1;
            final isSelected = frequency == _paymentFrequency;
            final installmentAmount = totalPrice / installments;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              option['label']!,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Selected',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormat.format(installmentAmount),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$installments payments over 3 months',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
