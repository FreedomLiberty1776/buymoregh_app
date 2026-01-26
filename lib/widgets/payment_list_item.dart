import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/payment.dart';

/// Consistent payment/collection list item used in:
/// - Collections tab
/// - Dashboard Recent Collections
/// - Contract detail (payments list)
///
/// Layout:
/// Line 1: Customer name
/// Line 2: Customer number / Contract number
/// Line 3: Product name
/// Line 4: Amount paid
/// Line 5: Date (left) and Status (right), spaced
class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final bool showCustomerAndContractLine;
  final bool showProductName;
  /// When true, horizontal margin is 0 (e.g. inside contract detail card).
  final bool compactMargin;
  final VoidCallback? onTap;

  const PaymentListItem({
    super.key,
    required this.payment,
    this.showCustomerAndContractLine = true,
    this.showProductName = true,
    this.compactMargin = false,
    this.onTap,
  });

  String _formatDate(DateTime dateTime) {
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
    final statusColor = _getStatusColor(payment.approvalStatus);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: compactMargin ? 0 : 16,
        vertical: 4,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
         
            const SizedBox(width: 12),
            // Lines 1–5: name, customer/contract id, product, amount, date + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line 1: Customer name
                  Text(
                    payment.customerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (showCustomerAndContractLine) ...[
                    const SizedBox(height: 2),
                    // Line 2: Customer number / Contract number
                    Text(
                      _buildCustomerContractLine(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (showProductName &&
                      payment.productName != null &&
                      payment.productName!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    // Line 3: Product name
                    Text(
                      payment.productName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Line 4: Amount paid
                  Text(
                    currencyFormat.format(payment.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                  ),
                  const SizedBox(height: 4),
                  // Line 5: Date (left) and Status (right), plus Pending sync if unsynced
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(payment.paymentDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!payment.isSynced)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.warningColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Pending sync',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.warningColor,
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              payment.approvalStatus.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right,
                  color: AppTheme.textHint, size: 20),
            ],
          ],
        ),
      ),
    );
  }

  String _buildCustomerContractLine() {
    final parts = <String>[];
    if (payment.customerNumber != null && payment.customerNumber!.isNotEmpty) {
      parts.add(payment.customerNumber!);
    }
    if (payment.contractNumber != null && payment.contractNumber!.isNotEmpty) {
      parts.add(payment.contractNumber!);
    }
    if (parts.isEmpty) return '—';
    return parts.join(' / ');
  }
}
