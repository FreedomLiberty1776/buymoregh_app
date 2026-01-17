import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/payment.dart';
import '../../widgets/payment_list_item.dart';
import '../payments/payment_detail_screen.dart';

enum TimeFilter { today, thisWeek, thisMonth }
enum PercentageFilter { all, lessThan50, between50And70, moreThan70 }

class CollectionsTab extends StatefulWidget {
  const CollectionsTab({super.key});

  @override
  State<CollectionsTab> createState() => _CollectionsTabState();
}

class _CollectionsTabState extends State<CollectionsTab> {
  TimeFilter _timeFilter = TimeFilter.today;
  PercentageFilter _percentageFilter = PercentageFilter.all;

  DateTime get _fromDate {
    final now = DateTime.now();
    switch (_timeFilter) {
      case TimeFilter.today:
        return DateTime(now.year, now.month, now.day);
      case TimeFilter.thisWeek:
        return now.subtract(Duration(days: now.weekday - 1));
      case TimeFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
    }
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      // Time filter
      final paymentDate = payment.paymentDate;
      if (paymentDate.isBefore(_fromDate)) {
        return false;
      }

      // Percentage filter
      final percentage = payment.contractPaymentPercentage ?? 0;
      switch (_percentageFilter) {
        case PercentageFilter.all:
          return true;
        case PercentageFilter.lessThan50:
          return percentage < 50;
        case PercentageFilter.between50And70:
          return percentage >= 50 && percentage <= 70;
        case PercentageFilter.moreThan70:
          return percentage > 70;
      }
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

              // Time Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _TimeFilterChip(
                          label: 'Today',
                          selected: _timeFilter == TimeFilter.today,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.today;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _TimeFilterChip(
                          label: 'This Week',
                          selected: _timeFilter == TimeFilter.thisWeek,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.thisWeek;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _TimeFilterChip(
                          label: 'This Month',
                          selected: _timeFilter == TimeFilter.thisMonth,
                          onTap: () {
                            setState(() {
                              _timeFilter = TimeFilter.thisMonth;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Percentage Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _PercentageFilterChip(
                          label: 'All',
                          selected: _percentageFilter == PercentageFilter.all,
                          onTap: () {
                            setState(() {
                              _percentageFilter = PercentageFilter.all;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _PercentageFilterChip(
                          label: '<50%',
                          selected: _percentageFilter == PercentageFilter.lessThan50,
                          onTap: () {
                            setState(() {
                              _percentageFilter = PercentageFilter.lessThan50;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _PercentageFilterChip(
                          label: '50-70%',
                          selected: _percentageFilter == PercentageFilter.between50And70,
                          onTap: () {
                            setState(() {
                              _percentageFilter = PercentageFilter.between50And70;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        _PercentageFilterChip(
                          label: '>70%',
                          selected: _percentageFilter == PercentageFilter.moreThan70,
                          onTap: () {
                            setState(() {
                              _percentageFilter = PercentageFilter.moreThan70;
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

class _TimeFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _PercentageFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PercentageFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? AppTheme.primaryColor : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
