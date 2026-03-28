import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../config/app_theme.dart';
import '../../models/contract.dart';
import '../../models/payment.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';

class AddPaymentScreen extends StatefulWidget {
  final Contract contract;

  const AddPaymentScreen({super.key, required this.contract});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _momoPhoneController = TextEditingController();
  final _otpController = TextEditingController();
  final ApiService _apiService = ApiService();

  PaymentMethod _selectedMethod = PaymentMethod.cash;
  bool _isSubmitting = false;
  bool _isSubmittingOtp = false;
  bool _isCheckingStatus = false;
  String? _errorMessage;
  String? _momoReference;
  String? _momoClientReference;
  String? _momoFlowMessage;
  String? _momoFlowError;
  bool _requiresOtp = false;

  @override
  void initState() {
    super.initState();
    final defaultPhone = widget.contract.customerPhone.trim();
    if (defaultPhone.isNotEmpty) {
      _momoPhoneController.text = defaultPhone;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _momoPhoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == PaymentMethod.mobileMoney) {
      await _startMobileMoneyCollection();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final appProvider = context.read<AppProvider>();

      // Offline-first: saves locally first, then syncs when online (idempotent via client_reference)
      await appProvider.createPayment(
        contract: widget.contract,
        amount: amount,
        paymentMethod: _getPaymentMethodString(_selectedMethod),
        momoPhone: _selectedMethod == PaymentMethod.mobileMoney
            ? _momoPhoneController.text
            : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            appProvider.isOnline
                ? 'Payment recorded successfully!'
                : 'Payment saved locally. It will sync when you have connection.',
          ),
          backgroundColor: AppTheme.completedStatus,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _resetMomoFlow({
    bool keepError = false,
    bool keepClientReference = false,
  }) {
    _momoReference = null;
    if (!keepClientReference) {
      _momoClientReference = null;
    }
    _momoFlowMessage = null;
    _requiresOtp = false;
    _otpController.clear();
    if (!keepError) {
      _momoFlowError = null;
    }
  }

  Future<void> _startMobileMoneyCollection() async {
    final appProvider = context.read<AppProvider>();
    if (!appProvider.isOnline) {
      setState(() {
        _errorMessage =
            'Mobile money collection needs internet connection. Save cash or bank payments offline, but MoMo must be initiated online.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _momoFlowError = null;
      _resetMomoFlow(keepClientReference: true);
    });

    try {
      final amount = double.parse(_amountController.text);
      _momoClientReference ??= const Uuid().v4();
      final response = await _apiService.initiatePaystackPayment(
        contractId: widget.contract.id,
        amount: amount,
        momoPhone: _momoPhoneController.text.trim(),
        clientReference: _momoClientReference,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _momoClientReference = null;
          _momoFlowError =
              response.error ?? 'Could not initiate the MoMo payment.';
        });
        return;
      }

      final result = response.data!;
      setState(() {
        _momoReference = result.reference;
        _momoFlowMessage =
            result.displayText ??
            'Payment initiated. Ask the customer to approve on the phone.';
        _requiresOtp = result.requiresOtp;
        _momoFlowError = null;
      });

      await appProvider.loadPayments(
        agentId: widget.contract.agentId,
        forceRefresh: true,
      );

      if (result.paid) {
        await _handleMobileMoneySuccess();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _momoFlowError = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _submitOtp() async {
    if ((_otpController.text).trim().isEmpty || _momoReference == null) {
      setState(() {
        _momoFlowError = 'Enter the OTP from the customer phone.';
      });
      return;
    }

    setState(() {
      _isSubmittingOtp = true;
      _momoFlowError = null;
    });

    try {
      final response = await _apiService.submitPaymentOtp(
        reference: _momoReference!,
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (!response.success || response.data == null) {
        setState(() {
          _momoFlowError = response.error ?? 'OTP submission failed.';
        });
        return;
      }

      final result = response.data!;
      setState(() {
        _requiresOtp = false;
        _momoFlowMessage =
            result.displayText ?? 'OTP accepted. Waiting for payment approval.';
        _momoFlowError = null;
      });

      if (result.paid) {
        await _handleMobileMoneySuccess();
        return;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _momoFlowError = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmittingOtp = false);
      }
    }
  }

  Future<void> _checkMobileMoneyStatus({
    bool showTransientErrors = true,
  }) async {
    if (_momoReference == null || _isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
    });

    try {
      final response = await _apiService.getPaymentStatus(_momoReference!);

      if (!mounted) return;

      if (!response.success || response.data == null) {
        if (showTransientErrors) {
          setState(() {
            _momoFlowError =
                response.error ?? 'Could not verify the payment status.';
          });
        }
        return;
      }

      final status = response.data!;
      setState(() {
        _momoFlowMessage =
            status.message ?? 'Payment is still waiting for confirmation.';
        _momoFlowError = null;
      });

      if (status.approvalStatus == 'APPROVED' ||
          status.paystackStatus == 'SUCCESS') {
        await _handleMobileMoneySuccess();
        return;
      }

      if (status.approvalStatus == 'REJECTED' ||
          status.paystackStatus == 'FAILED') {
        setState(() {
          _momoClientReference = null;
          _momoFlowError =
              status.message ?? 'Payment was not successful. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      if (showTransientErrors) {
        setState(() {
          _momoFlowError = 'Error: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  Future<void> _handleMobileMoneySuccess() async {
    final appProvider = context.read<AppProvider>();
    await appProvider.loadAllData(
      agentId: widget.contract.agentId,
      forceRefresh: true,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mobile money payment confirmed successfully.'),
        backgroundColor: AppTheme.completedStatus,
      ),
    );

    Navigator.pop(context, true);
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
    final currencyFormat = NumberFormat.currency(
      symbol: 'GHS ',
      decimalDigits: 2,
    );
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
                            currencyFormat.format(
                              widget.contract.outstandingBalance,
                            ),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    border: Border.all(
                      color: AppTheme.errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
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
                  enabled: _momoReference == null || _momoFlowError != null,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
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
                    enabled: _momoReference == null || _momoFlowError != null,
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
                  enabled: _momoReference == null || _momoFlowError != null,
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

              if (_selectedMethod == PaymentMethod.mobileMoney) ...[
                const SizedBox(height: 16),
                _buildMomoFlowCard(context),
              ],

              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_isSubmitting ||
                          (_momoReference != null && _momoFlowError == null))
                      ? null
                      : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppTheme.primaryColor.withOpacity(
                      0.5,
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _selectedMethod == PaymentMethod.mobileMoney
                              ? (_momoReference != null &&
                                        _momoFlowError == null
                                    ? 'Collection Initiated'
                                    : _momoFlowError != null
                                    ? 'Start New Collection'
                                    : 'Initiate Collection')
                              : 'Record Payment',
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
                  _selectedMethod == PaymentMethod.mobileMoney
                      ? 'Mobile money collections are created on the server first, then confirmed asynchronously through Paystack.'
                      : 'Payment will be submitted for approval',
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

  Widget _buildSummaryItem(
    String label,
    String value,
    BuildContext context, {
    Color? color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
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

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    IconData icon,
  ) {
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
        if (_momoReference != null && _momoFlowError == null) return;
        setState(() {
          _selectedMethod = method;
          _errorMessage = null;
          if (method == PaymentMethod.mobileMoney &&
              _momoPhoneController.text.trim().isEmpty &&
              widget.contract.customerPhone.trim().isNotEmpty) {
            _momoPhoneController.text = widget.contract.customerPhone.trim();
          }
          if (method != PaymentMethod.mobileMoney) {
            _resetMomoFlow();
          }
        });
      },
    );
  }

  Widget _buildMomoFlowCard(BuildContext context) {
    final bool hasActiveFlow = _momoReference != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActiveFlow
              ? AppTheme.primaryColor.withOpacity(0.25)
              : AppTheme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobile Money Collection',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _momoFlowMessage ??
                'We will save the payment on the backend first, then send a prompt to the customer phone. If Paystack asks for OTP, enter it here. After that, use Check Status to confirm the final outcome.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          if (_momoReference != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    color: AppTheme.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reference: $_momoReference',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_momoFlowError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _momoFlowError!,
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_requiresOtp && _momoReference != null) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              enabled: !_isSubmittingOtp,
              decoration: InputDecoration(
                labelText: 'OTP',
                hintText: 'Enter OTP from customer phone',
                prefixIcon: const Icon(Icons.password),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmittingOtp ? null : _submitOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _isSubmittingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Submit OTP'),
                  ),
                ),
              ],
            ),
          ] else if (_momoReference != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCheckingStatus
                    ? null
                    : () => _checkMobileMoneyStatus(),
                icon: const Icon(Icons.sync),
                label: Text(
                  _isCheckingStatus ? 'Checking...' : 'Check Status Now',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
