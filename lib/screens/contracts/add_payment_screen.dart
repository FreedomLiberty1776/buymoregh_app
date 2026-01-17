import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_theme.dart';
import '../../models/contract.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final Contract contract;

  const AddPaymentScreen({
    super.key,
    required this.contract,
  });

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _momoPhoneController = TextEditingController();
  
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _momoPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      final amount = double.parse(_amountController.text);
      final clientReference = const Uuid().v4();
      
      final api = ApiService();
      final result = await api.createPayment(
        contractId: widget.contract.id,
        amount: amount,
        paymentMethod: _getPaymentMethodString(_selectedMethod),
        clientReference: clientReference,
        momoPhone: _selectedMethod == PaymentMethod.mobileMoney 
            ? _momoPhoneController.text 
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      if (!mounted) return;
      
      if (result.success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Payment recorded successfully!'),
            backgroundColor: AppTheme.completedStatus,
          ),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Failed to record payment';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getPaymentMethodString(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.mobileMoney:
        return 'MOMO';
      case PaymentMethod.bankTransfer:
        return 'BANK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final percentage = widget.contract.paymentPercentage.clamp(0, 100);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Record Payment',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contract Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.contract.customerName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.contract.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Divider(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            'Total',
                            currencyFormat.format(widget.contract.totalAmount),
                            context,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Paid',
                            currencyFormat.format(widget.contract.totalPaid),
                            context,
                            color: AppTheme.completedStatus,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            'Balance',
                            currencyFormat.format(widget.contract.outstandingBalance),
                            context,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppTheme.progressBackground,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.progressFilled,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${percentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Details
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Amount Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Amount (GHS)',
                    hintText: 'Enter payment amount',
                    prefixText: 'GHS ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    if (amount > widget.contract.outstandingBalance) {
                      return 'Amount cannot exceed outstanding balance (${currencyFormat.format(widget.contract.outstandingBalance)})';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Payment Method
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildPaymentMethodTile(
                      PaymentMethod.cash,
                      'Cash',
                      Icons.payments,
                    ),
                    const Divider(height: 1),
                    _buildPaymentMethodTile(
                      PaymentMethod.mobileMoney,
                      'Mobile Money',
                      Icons.phone_android,
                    ),
                    const Divider(height: 1),
                    _buildPaymentMethodTile(
                      PaymentMethod.bankTransfer,
                      'Bank Transfer',
                      Icons.account_balance,
                    ),
                  ],
                ),
              ),
              
              // MoMo Phone Field (shown only for Mobile Money)
              if (_selectedMethod == PaymentMethod.mobileMoney) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextFormField(
                    controller: _momoPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'MoMo Phone Number',
                      hintText: 'e.g., 0244123456',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (_selectedMethod == PaymentMethod.mobileMoney) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter MoMo phone number';
                        }
                        if (value.length < 10) {
                          return 'Please enter a valid phone number';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Notes Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any notes about this payment',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(Icons.notes),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Record Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info Text
              Center(
                child: Text(
                  'Payment will be submitted for approval',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, BuildContext context, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethod method, String title, IconData icon) {
    final isSelected = _selectedMethod == method;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
          : const Icon(Icons.circle_outlined, color: AppTheme.dividerColor),
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
    );
  }
}
