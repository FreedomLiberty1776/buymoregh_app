import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/payment.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Payment payment;

  const PaymentDetailScreen({
    super.key,
    required this.payment,
  });

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isCheckingDigitalStatus = false;
  late Payment _payment;

  Payment get payment => _payment;

  @override
  void initState() {
    super.initState();
    _payment = widget.payment;
  }

  Future<void> _checkDigitalStatus() async {
    final reference = payment.paystackReference;
    if (_isCheckingDigitalStatus || reference == null || reference.isEmpty) {
      return;
    }

    setState(() => _isCheckingDigitalStatus = true);

    try {
      final response = await _apiService.getPaymentStatus(reference);
      if (!mounted) return;

      if (!response.success || response.data == null) {
        throw Exception(response.error ?? 'Could not check payment status.');
      }

      final appProvider = context.read<AppProvider>();
      final agentId = context.read<AuthProvider>().user?.id;
      await appProvider.loadAllData(agentId: agentId, forceRefresh: true);

      final status = response.data!;
      final updatedPayment = _findUpdatedPayment(appProvider, status);
      if (updatedPayment != null && mounted) {
        setState(() {
          _payment = updatedPayment;
        });
      } else if (mounted) {
        setState(() {
          _payment = _copyPaymentWithStatus(status);
        });
      }

      final paystackStatus =
          (status.paystackStatus ?? payment.paystackStatus ?? '').toUpperCase();
      final approvalStatus =
          (status.approvalStatus ??
                  payment.approvalStatus.name.toUpperCase())
              .toUpperCase();

      String message;
      Color color;
      if (approvalStatus == 'APPROVED' || paystackStatus == 'SUCCESS') {
        message = 'Payment confirmed and details refreshed.';
        color = AppTheme.completedStatus;
      } else if (approvalStatus == 'REJECTED' || paystackStatus == 'FAILED') {
        message = 'This payment failed. The details have been refreshed.';
        color = AppTheme.errorColor;
      } else if (paystackStatus == 'SEND_OTP') {
        message = 'This payment still requires OTP confirmation.';
        color = AppTheme.warningColor;
      } else {
        message = 'Payment is still pending. You can check again later.';
        color = AppTheme.warningColor;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not check payment status: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingDigitalStatus = false);
      }
    }
  }

  Payment? _findUpdatedPayment(
    AppProvider appProvider,
    PaymentStatusResult status,
  ) {
    final allPayments = <Payment>[
      ...appProvider.payments,
      ...appProvider.recentPayments,
      ...appProvider.unsyncedPayments,
    ];

    for (final candidate in allPayments) {
      final sameId = status.paymentId != null && candidate.id == status.paymentId;
      final sameReference =
          candidate.paystackReference != null &&
          candidate.paystackReference == payment.paystackReference;
      if (sameId || sameReference) {
        return candidate;
      }
    }
    return null;
  }

  Payment _copyPaymentWithStatus(PaymentStatusResult status) {
    return Payment(
      id: payment.id,
      contractId: payment.contractId,
      customerId: payment.customerId,
      customerName: payment.customerName,
      customerPhone: payment.customerPhone,
      customerNumber: payment.customerNumber,
      contractNumber: payment.contractNumber,
      agentId: payment.agentId,
      agentName: payment.agentName,
      amount: payment.amount,
      paymentMethod: payment.paymentMethod,
      momoPhone: payment.momoPhone,
      approvalStatus: PaymentApprovalStatus.fromString(
        status.approvalStatus ?? payment.approvalStatus.name,
      ),
      rejectionReason: payment.rejectionReason,
      approvedAt: payment.approvedAt,
      approvedBy: payment.approvedBy,
      clientReference: payment.clientReference,
      paystackReference: payment.paystackReference,
      paystackStatus: status.paystackStatus ?? payment.paystackStatus,
      paymentDate: payment.paymentDate,
      createdAt: payment.createdAt,
      updatedAt: DateTime.now(),
      notes: payment.notes,
      productName: payment.productName,
      productId: payment.productId,
      contractTotalAmount: payment.contractTotalAmount,
      contractOutstandingBalance: payment.contractOutstandingBalance,
      contractTotalPaid: payment.contractTotalPaid,
      contractPaymentPercentage: payment.contractPaymentPercentage,
      balanceBefore: payment.balanceBefore,
      balanceAfter: payment.balanceAfter,
      isSynced: payment.isSynced,
      localUniqueId: payment.localUniqueId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Details',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Amount Card
            _buildAmountCard(context, currencyFormat),
            
            const SizedBox(height: 16),
            
            // Status Card
            _buildStatusCard(context),

            if (_hasDigitalCollectionStatus()) ...[
              const SizedBox(height: 16),
              _buildDigitalCollectionCard(context),
            ],
            
            const SizedBox(height: 16),
            
            // Contract Info Card
            _buildContractCard(context, currencyFormat),
            
            const SizedBox(height: 16),
            
            // Balance Info Card
            _buildBalanceCard(context, currencyFormat),
            
            const SizedBox(height: 16),
            
            // Payment Details Card
            _buildDetailsCard(context, dateTimeFormat),
            
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildNotesCard(context),
            ],
            if (!payment.isSynced) ...[
              const SizedBox(height: 24),
              _buildSyncNowCard(context),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncNowCard(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isSyncing = appProvider.isSyncingPending || appProvider.isSyncing;
    final isOnline = appProvider.isOnline;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_upload, color: AppTheme.warningColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Not synced',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningColor,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isOnline
                ? 'This payment is saved locally. Tap below to send it to the server.'
                : 'This payment is saved locally. It will sync when you\'re back online.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          if (isOnline) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSyncing
                    ? null
                    : () async {
                        await appProvider.triggerSync(
                          agentId: context.read<AuthProvider>().user?.id,
                        );
                        if (context.mounted) {
                          final stillUnsynced = appProvider.unsyncedPayments
                              .any((p) => p.clientReference == payment.clientReference);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                stillUnsynced
                                    ? 'Sync in progress or could not sync. Try again.'
                                    : 'Payment synced.',
                              ),
                              backgroundColor: stillUnsynced
                                  ? AppTheme.warningColor
                                  : AppTheme.completedStatus,
                            ),
                          );
                          if (!stillUnsynced && context.mounted) {
                            Navigator.pop(context, true);
                          }
                        }
                      },
                icon: isSyncing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.cloud_upload, size: 20),
                label: Text(isSyncing ? 'Syncing...' : 'Sync now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context, NumberFormat currencyFormat) {
    Color statusColor;
    switch (payment.approvalStatus) {
      case PaymentApprovalStatus.approved:
        statusColor = AppTheme.completedStatus;
        break;
      case PaymentApprovalStatus.pending:
        statusColor = AppTheme.warningColor;
        break;
      case PaymentApprovalStatus.rejected:
        statusColor = AppTheme.errorColor;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(
              _getPaymentIcon(),
              size: 32,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            currencyFormat.format(payment.amount),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            payment.paymentMethod.displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon() {
    switch (payment.paymentMethod) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.mobileMoney:
        return Icons.phone_android;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (payment.approvalStatus) {
      case PaymentApprovalStatus.approved:
        statusColor = AppTheme.completedStatus;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case PaymentApprovalStatus.pending:
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.schedule;
        statusText = 'Pending Approval';
        break;
      case PaymentApprovalStatus.rejected:
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (payment.rejectionReason != null && payment.rejectionReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      payment.rejectionReason!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasDigitalCollectionStatus() {
    return payment.paymentMethod == PaymentMethod.mobileMoney ||
        (payment.paystackReference != null && payment.paystackReference!.isNotEmpty) ||
        (payment.paystackStatus != null && payment.paystackStatus!.isNotEmpty);
  }

  String _normalizedDigitalStatus() {
    return (payment.paystackStatus ?? '').toUpperCase();
  }

  Color _getDigitalStatusColor() {
    switch (_normalizedDigitalStatus()) {
      case 'SUCCESS':
        return AppTheme.completedStatus;
      case 'FAILED':
        return AppTheme.errorColor;
      case 'SEND_OTP':
      case 'PENDING':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getDigitalStatusIcon() {
    switch (_normalizedDigitalStatus()) {
      case 'SUCCESS':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.cancel;
      case 'SEND_OTP':
        return Icons.password;
      case 'PENDING':
        return Icons.schedule;
      default:
        return Icons.info;
    }
  }

  String _getDigitalStatusLabel() {
    final normalized = _normalizedDigitalStatus();
    switch (normalized) {
      case 'SUCCESS':
        return 'Successful';
      case 'FAILED':
        return 'Failed';
      case 'SEND_OTP':
        return 'OTP Required';
      case 'PENDING':
        return 'Pending';
      default:
        return normalized.isEmpty ? 'Not Started' : normalized.replaceAll('_', ' ');
    }
  }

  String _getDigitalStatusDescription() {
    switch (_normalizedDigitalStatus()) {
      case 'SUCCESS':
        return 'Paystack has confirmed this mobile money collection.';
      case 'FAILED':
        return 'The mobile money collection did not complete successfully.';
      case 'SEND_OTP':
        return 'The customer still needs to provide an OTP from the phone.';
      case 'PENDING':
        return 'Waiting for customer approval or final Paystack confirmation.';
      default:
        return _normalizedDigitalStatus().isEmpty
            ? 'No Paystack gateway status has been recorded yet.'
            : 'Latest Paystack gateway status for this payment.';
    }
  }

  Widget _buildDigitalCollectionCard(BuildContext context) {
    final statusColor = _getDigitalStatusColor();
    final statusIcon = _getDigitalStatusIcon();
    final statusLabel = _getDigitalStatusLabel();
    final statusDescription = _getDigitalStatusDescription();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital Collection',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusDescription,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (payment.paystackReference != null && payment.paystackReference!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              Icons.confirmation_number,
              'Paystack Ref',
              payment.paystackReference!,
            ),
          ],
          if (payment.paystackStatus != null && payment.paystackStatus!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.sync,
              'Gateway Status',
              payment.paystackStatus!.replaceAll('_', ' '),
            ),
          ],
          if (payment.paystackReference != null &&
              payment.paystackReference!.isNotEmpty &&
              payment.approvalStatus == PaymentApprovalStatus.pending) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCheckingDigitalStatus ? null : _checkDigitalStatus,
                icon: _isCheckingDigitalStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _isCheckingDigitalStatus ? 'Checking...' : 'Check Status',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, NumberFormat currencyFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contract Information',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Customer
          _buildInfoRow(
            context,
            Icons.person,
            'Customer',
            payment.customerName,
          ),
          
          if (payment.customerPhone != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.phone,
              'Phone',
              payment.customerPhone!,
            ),
          ],
          
          // Product
          if (payment.productName != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.shopping_bag,
              'Product',
              payment.productName!,
            ),
          ],
          
          // Contract Total
          if (payment.contractTotalAmount != null && payment.contractTotalAmount! > 0) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.receipt,
              'Contract Total',
              currencyFormat.format(payment.contractTotalAmount),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, NumberFormat currencyFormat) {
    final percentage = payment.contractPaymentPercentage ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Balance Information',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Balance before and after
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance Before',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(payment.balanceBefore ?? 0),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: AppTheme.textHint),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Balance After',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(payment.balanceAfter ?? payment.contractOutstandingBalance ?? 0),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: (payment.balanceAfter ?? 0) <= 0 
                            ? AppTheme.completedStatus 
                            : AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.progressBackground,
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 100 ? AppTheme.completedStatus : AppTheme.progressFilled,
              ),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid: ${currencyFormat.format(payment.contractTotalPaid ?? 0)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.completedStatus,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}% Complete',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(BuildContext context, DateFormat dateTimeFormat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildInfoRow(
            context,
            Icons.calendar_today,
            'Date',
            dateTimeFormat.format(payment.paymentDate),
          ),
          
          if (payment.agentName != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.person_outline,
              'Recorded by',
              payment.agentName!,
            ),
          ],
          
          if (payment.clientReference != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.tag,
              'Reference',
              payment.clientReference!,
            ),
          ],
          
          if (payment.momoPhone != null && payment.momoPhone!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.phone_android,
              'MoMo Number',
              payment.momoPhone!,
            ),
          ],
          
          if (payment.paystackReference != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              context,
              Icons.confirmation_number,
              'Paystack Ref',
              payment.paystackReference!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, size: 18, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                'Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            payment.notes!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
