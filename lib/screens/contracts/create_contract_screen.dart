import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _depositController = TextEditingController(text: '0');
  String _paymentFrequency = 'DAILY';
  DateTime? _startDate;
  DateTime? _endDate;
  final _releaseThresholdController = TextEditingController(text: '75');

  List<Product> _products = [];
  bool _loadingProducts = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<Map<String, String>> _frequencyOptions = [
    {'value': 'DAILY', 'label': 'Daily'},
    {'value': 'WEEKLY', 'label': 'Weekly'},
    {'value': 'BI_WEEKLY', 'label': 'Bi-Weekly'},
    {'value': 'MONTHLY', 'label': 'Monthly'},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositController.dispose();
    _releaseThresholdController.dispose();
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
      }
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
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

    final totalPrice = double.tryParse(_totalPriceController.text.trim());
    final deposit = double.tryParse(_depositController.text.trim()) ?? 0;
    if (totalPrice == null || totalPrice <= 0) {
      setState(() => _errorMessage = 'Total price must be greater than zero.');
      return;
    }
    if (deposit < 0) {
      setState(() => _errorMessage = 'Deposit amount cannot be negative.');
      return;
    }
    if (deposit > totalPrice) {
      setState(() => _errorMessage = 'Deposit amount cannot exceed total price.');
      return;
    }
    final threshold = int.tryParse(_releaseThresholdController.text.trim()) ?? 75;
    if (threshold < 0 || threshold > 100) {
      setState(() => _errorMessage = 'Release threshold must be between 0 and 100.');
      return;
    }
    if (_startDate == null) {
      setState(() => _errorMessage = 'Please select a start date.');
      return;
    }

    setState(() => _isSubmitting = true);

    final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endStr = _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    final res = await _api.createContract(
      customerId: _selectedCustomer!.id,
      productId: _selectedProduct!.id,
      totalPrice: totalPrice,
      depositAmount: deposit,
      paymentFrequency: _paymentFrequency,
      expectedStartDate: startStr,
      expectedEndDate: endStr,
      releaseThresholdPercentage: threshold,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (res.success) {
      final appProvider = context.read<AppProvider>();
      final authProvider = context.read<AuthProvider>();
      await appProvider.loadContracts(agentId: authProvider.user?.id, forceRefresh: true);
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = res.error ?? 'Failed to create contract.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

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
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Customer
              const Text('Customer *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Customer?>(
                value: _selectedCustomer,
                decoration: _inputDecoration(),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Select customer')),
                  ...appProvider.customers
                      .where((c) => c.isActive)
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.fullName} - ${c.phoneNumber}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ))
                ],
                onChanged: (c) => setState(() => _selectedCustomer = c),
              ),
              const SizedBox(height: 20),
              // Product
              const Text('Product *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _loadingProducts
                  ? const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()))
                  : DropdownButtonFormField<Product?>(
                      value: _selectedProduct,
                      decoration: _inputDecoration(),
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Select product')),
                        ..._products
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    '${p.name} - ${currencyFormat.format(p.sellingPrice)}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ))
                      ],
                      onChanged: _onProductChanged,
                    ),
              const SizedBox(height: 20),
              // Total price & Deposit
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Price (GHS) *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _totalPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          decoration: _inputDecoration(),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Required';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deposit (GHS)', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _depositController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          decoration: _inputDecoration(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Payment frequency
              const Text('Payment Frequency *', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _paymentFrequency,
                decoration: _inputDecoration(),
                items: _frequencyOptions
                    .map((e) => DropdownMenuItem(value: e['value'], child: Text(e['label']!)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentFrequency = v ?? 'DAILY'),
              ),
              const SizedBox(height: 20),
              // Start & End date
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date *', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickDate(true),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                color: _startDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Expected End Date', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _pickDate(false),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.dividerColor),
                            ),
                            child: Text(
                              _endDate != null
                                  ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                  : 'Optional',
                              style: TextStyle(
                                color: _endDate != null ? AppTheme.textPrimary : AppTheme.textHint,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Release threshold
              const Text('Release Threshold (%)', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Product released when customer pays this percentage',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _releaseThresholdController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
