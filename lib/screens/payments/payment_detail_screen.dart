import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../models/payment.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailScreen({
    super.key,
    required this.payment,
  });

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
            
            const SizedBox(height: 32),
          ],
        ),
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
