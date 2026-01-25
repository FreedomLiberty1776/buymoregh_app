import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/payment_list_item.dart';
import '../profile/profile_screen.dart';
import '../payments/payment_detail_screen.dart';
import '../products/products_screen.dart';

class DashboardTab extends StatelessWidget {
  final void Function(int index)? onSwitchToTab;

  const DashboardTab({super.key, this.onSwitchToTab});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final agentId = authProvider.user?.id;
            await appProvider.loadAllData(agentId: agentId, forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar - tappable for profile
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              authProvider.user?.fullName.isNotEmpty == true
                                  ? authProvider.user!.fullName[0].toUpperCase()
                                  : 'A',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Greeting - also tappable for profile
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${authProvider.user?.firstName ?? 'Agent'}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Online status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: appProvider.isOnline
                              ? AppTheme.successColor.withOpacity(0.1)
                              : AppTheme.textSecondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: appProvider.isOnline
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              appProvider.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: appProvider.isOnline
                                    ? AppTheme.successColor
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Customers Card
                      StatCard(
                        icon: Icons.people_outline,
                        label: 'Customers',
                        value: appProvider.customerCount.toString(),
                        isLoading: appProvider.isLoadingDashboard,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Pending Approvals Card
                      StatCard(
                        icon: Icons.pending_actions_outlined,
                        label: 'Pending Approvals',
                        value: currencyFormat.format(appProvider.pendingApprovals),
                        isLoading: appProvider.isLoadingDashboard,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Today's Collections Card - tappable to go to Collections
                      _TapStatCard(
                        icon: Icons.calendar_today_outlined,
                        label: "Today's Collections",
                        value: currencyFormat.format(appProvider.todayCollections),
                        valueColor: AppTheme.primaryColor,
                        isLoading: appProvider.isLoadingDashboard,
                        onTap: () => onSwitchToTab?.call(3),
                      ),
                      const SizedBox(height: 12),
                      // Products Card - tappable to open read-only products list
                      _TapStatCard(
                        icon: Icons.inventory_2_outlined,
                        label: 'Products',
                        value: 'View catalog',
                        valueColor: AppTheme.primaryColor,
                        isLoading: false,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProductsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Collections Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Collections',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => onSwitchToTab?.call(3),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Collections List
              if (appProvider.isLoadingDashboard)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (appProvider.recentPayments.isEmpty)
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
                            'No collections yet',
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
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final payment = appProvider.recentPayments[index];
                      return PaymentListItem(
                        payment: payment,
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
                    childCount: appProvider.recentPayments.length,
                  ),
                ),

              // Bottom padding
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLoading;
  final VoidCallback? onTap;

  const _TapStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isLoading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = StatCard(
      icon: icon,
      label: label,
      value: value,
      valueColor: valueColor,
      isLoading: isLoading,
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: child,
    );
  }
}
