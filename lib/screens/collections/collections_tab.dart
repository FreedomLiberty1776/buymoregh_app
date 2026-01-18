import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/payment.dart';
import '../../widgets/payment_list_item.dart';
import '../payments/payment_detail_screen.dart';

enum TimeFilter { all, today, thisWeek, thisMonth, thisYear, custom }
enum StatusFilter { all, approved, pending, rejected }

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  TimeFilter _timeFilter = TimeFilter.all;
  StatusFilter _statusFilter = StatusFilter.all;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  DateTime? get _fromDate {
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.all:
        return null;
      case TimeFilter.today:
        return DateTime(now.year, now.month, now.day);
      case TimeFilter.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case TimeFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
      case TimeFilter.thisYear:
        return DateTime(now.year, 1, 1);
      case TimeFilter.custom:
        return _customStartDate;
    }
  }

  DateTime? get _toDate {
    if (_timeFilter == TimeFilter.custom) {
      return _customEndDate;
    }
    return null;
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _timeFilter = TimeFilter.custom;
      });
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      // Time filter
      final paymentDate = payment.paymentDate;
      final fromDate = _fromDate;
      final toDate = _toDate;
      
      if (fromDate != null && paymentDate.isBefore(fromDate)) {
        return false;
      }
      if (toDate != null && paymentDate.isAfter(toDate.add(const Duration(days: 1)))) {
        return false;
      }

      // Status filter
      switch (_statusFilter) {
        case StatusFilter.all:
          break;
        case StatusFilter.approved:
          if (payment.approvalStatus != PaymentApprovalStatus.approved) return false;
          break;
        case StatusFilter.pending:
          if (payment.approvalStatus != PaymentApprovalStatus.pending) return false;
          break;
        case StatusFilter.rejected:
          if (payment.approvalStatus != PaymentApprovalStatus.rejected) return false;
          break;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final filteredPayments = _filterPayments(appProvider.payments);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final agentId = authProvider.user?.id;
            await appProvider.loadPayments(agentId: agentId, forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // Header with Avatar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Collections',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            authProvider.user?.firstName.isNotEmpty == true
                                ? authProvider.user!.firstName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Period Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All Time',
                          selected: _timeFilter == TimeFilter.all,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.all;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Today',
                          selected: _timeFilter == TimeFilter.today,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.today;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'This Week',
                          selected: _timeFilter == TimeFilter.thisWeek,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.thisWeek;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'This Month',
                          selected: _timeFilter == TimeFilter.thisMonth,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.thisMonth;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'This Year',
                          selected: _timeFilter == TimeFilter.thisYear,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.thisYear;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: _timeFilter == TimeFilter.custom && _customStartDate != null
                              ? '${_customStartDate!.day}/${_customStartDate!.month} - ${_customEndDate?.day}/${_customEndDate?.month}'
                              : 'Custom',
                          selected: _timeFilter == TimeFilter.custom,
                          icon: Icons.calendar_today,
                          onTap: _selectCustomDateRange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatusFilterChip(
                          label: 'All',
                          selected: _statusFilter == StatusFilter.all,
                          onTap: () {
                            setState(() {
                              _statusFilter = StatusFilter.all;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _StatusFilterChip(
                          label: 'Approved',
                          selected: _statusFilter == StatusFilter.approved,
                          color: AppTheme.successColor,
                          onTap: () {
                            setState(() {
                              _statusFilter = StatusFilter.approved;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _StatusFilterChip(
                          label: 'Pending',
                          selected: _statusFilter == StatusFilter.pending,
                          color: AppTheme.warningColor,
                          onTap: () {
                            setState(() {
                              _statusFilter = StatusFilter.pending;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _StatusFilterChip(
                          label: 'Rejected',
                          selected: _statusFilter == StatusFilter.rejected,
                          color: AppTheme.errorColor,
                          onTap: () {
                            setState(() {
                              _statusFilter = StatusFilter.rejected;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Payments List
              if (appProvider.isLoadingPayments)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (filteredPayments.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No collections found',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payment = filteredPayments[index];
                        return PaymentListItem(
                          payment: payment,
                          showPercentage: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentDetailScreen(payment: payment),
                              ),
                            );
                          },
                        );
                      },
                      childCount: filteredPayments.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _StatusFilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.primaryColor;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : AppTheme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? chipColor : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
