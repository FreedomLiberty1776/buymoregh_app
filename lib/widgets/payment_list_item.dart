import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/payment.dart';

class PaymentListItem extends StatelessWidget {
  final Payment payment;
  final bool showPercentage;
  final VoidCallback? onTap;

  const PaymentListItem({
    super.key,
    required this.payment,
    this.showPercentage = false,
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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final percentage = payment.contractPaymentPercentage ?? 0;

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
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  payment.customerName.isNotEmpty
                      ? payment.customerName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Name and Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.customerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(payment.paymentDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            
            // Amount and Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(payment.amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
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
