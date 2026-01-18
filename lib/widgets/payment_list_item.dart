import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/payment.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final bool showPercentage;
  final bool showStatus;
  final bool showCustomerNumber;
  final bool showProductName;
  final VoidCallback? onTap;

  const PaymentListItem({
    super.key,
    required this.payment,
    this.showPercentage = false,
    this.showStatus = true,
    this.showCustomerNumber = true,
    this.showProductName = true,
    this.onTap,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final paymentDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (paymentDay == today) {
      return DateFormat.jm().format(dateTime);
    } else if (paymentDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      return DateFormat.MMMd().add_jm().format(dateTime);
    }
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 100) return AppTheme.successColor;
    if (percentage >= 70) return AppTheme.primaryColor;
    if (percentage >= 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Color _getStatusColor(PaymentApprovalStatus status) {
    switch (status) {
      case PaymentApprovalStatus.approved:
        return AppTheme.successColor;
      case PaymentApprovalStatus.pending:
        return AppTheme.warningColor;
      case PaymentApprovalStatus.rejected:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final percentage = payment.contractPaymentPercentage ?? 0;
    final statusColor = _getStatusColor(payment.approvalStatus);

    // Build customer display name with customer number
    String customerDisplay = payment.customerName;
    if (showCustomerNumber && payment.customerNumber != null && payment.customerNumber!.isNotEmpty) {
      customerDisplay = '${payment.customerName} (${payment.customerNumber})';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      payment.customerName.isNotEmpty
                          ? payment.customerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(width: 12),
            
            // Name, Product, Time and Status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerDisplay,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Product name if available
                  if (showProductName && payment.productName != null && payment.productName!.isNotEmpty) ...[
                    Text(
                      payment.productName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatTime(payment.paymentDate),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      if (showStatus) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            payment.approvalStatus.displayName,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Amount and Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(payment.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                if (showPercentage) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${percentage.toStringAsFixed(0)}% collected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getPercentageColor(percentage),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
