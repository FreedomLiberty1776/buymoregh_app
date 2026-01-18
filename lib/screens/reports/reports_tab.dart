import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/contract.dart';
import '../auth/login_screen.dart';

class ReportsTab extends StatelessWidget {
  const ReportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

    // Calculate report data
    final totalContracts = appProvider.contracts.length;
    final activeContracts = appProvider.contracts
        .where((c) => c.status == ContractStatus.active)
        .length;
    final completedContracts = appProvider.contracts
        .where((c) => c.status == ContractStatus.completed)
        .length;
    final overdueContracts = appProvider.overdueContracts.length;
    
    final totalOutstanding = appProvider.contracts.fold<double>(
      0,
      (sum, c) => sum + c.outstandingBalance,
    );
    final totalCollected = appProvider.contracts.fold<double>(
      0,
      (sum, c) => sum + c.totalPaid,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Reports',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Summary Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Contract Summary
                    _ReportCard(
                      title: 'Contract Summary',
                      icon: Icons.description_outlined,
                      children: [
                        _ReportRow(
                          label: 'Total Contracts',
                          value: totalContracts.toString(),
                        ),
                        _ReportRow(
                          label: 'Active',
                          value: activeContracts.toString(),
                          valueColor: AppTheme.activeStatus,
                        ),
                        _ReportRow(
                          label: 'Completed',
                          value: completedContracts.toString(),
                          valueColor: AppTheme.completedStatus,
                        ),
                        _ReportRow(
                          label: 'Overdue',
                          value: overdueContracts.toString(),
                          valueColor: AppTheme.overdueStatus,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Financial Summary
                    _ReportCard(
                      title: 'Financial Summary',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        _ReportRow(
                          label: 'Total Collected',
                          value: currencyFormat.format(totalCollected),
                          valueColor: AppTheme.successColor,
                        ),
                        _ReportRow(
                          label: 'Outstanding Balance',
                          value: currencyFormat.format(totalOutstanding),
                          valueColor: AppTheme.warningColor,
                        ),
                        _ReportRow(
                          label: "Today's Collections",
                          value: currencyFormat.format(appProvider.todayCollections),
                        ),
                        _ReportRow(
                          label: 'Pending Approvals',
                          value: currencyFormat.format(appProvider.pendingApprovals),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Sync Status
                    _ReportCard(
                      title: 'Sync Status',
                      icon: Icons.sync,
                      children: [
                        _ReportRow(
                          label: 'Connection',
                          value: appProvider.isOnline ? 'Online' : 'Offline',
                          valueColor: appProvider.isOnline
                              ? AppTheme.successColor
                              : AppTheme.textSecondary,
                        ),
                        _ReportRow(
                          label: 'Pending Sync',
                          value: appProvider.hasPendingSync ? 'Yes' : 'No',
                          valueColor: appProvider.hasPendingSync
                              ? AppTheme.warningColor
                              : AppTheme.successColor,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Logout Button
                    // SizedBox(
                    //   width: double.infinity,
                    //   child: OutlinedButton.icon(
                    //     onPressed: () async {
                    //       final confirm = await showDialog<bool>(
                    //         context: context,
                    //         builder: (context) => AlertDialog(
                    //           title: const Text('Logout'),
                    //           content: const Text(
                    //             'Are you sure you want to logout? Any unsynced data will be preserved.',
                    //           ),
                    //           actions: [
                    //             TextButton(
                    //               onPressed: () => Navigator.pop(context, false),
                    //               child: const Text('Cancel'),
                    //             ),
                    //             TextButton(
                    //               onPressed: () => Navigator.pop(context, true),
                    //               style: TextButton.styleFrom(
                    //                 foregroundColor: AppTheme.errorColor,
                    //               ),
                    //               child: const Text('Logout'),
                    //             ),
                    //           ],
                    //         ),
                    //       );

                    //       if (confirm == true && context.mounted) {
                    //         await authProvider.logout();
                    //         if (context.mounted) {
                    //           Navigator.of(context).pushReplacement(
                    //             MaterialPageRoute(
                    //               builder: (_) => const LoginScreen(),
                    //             ),
                    //           );
                    //         }
                    //       }
                    //     },
                    //     icon: const Icon(Icons.logout),
                    //     label: const Text('Logout'),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: AppTheme.errorColor,
                    //       side: const BorderSide(color: AppTheme.errorColor),
                    //       padding: const EdgeInsets.symmetric(vertical: 14),
                    //     ),
                    //   ),
                    // ),
                  
                  
                  ],
                ),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ReportCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
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
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReportRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
