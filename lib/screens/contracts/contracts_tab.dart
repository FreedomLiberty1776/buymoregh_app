import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/contract.dart';
import 'contract_detail_screen.dart';
import 'add_payment_screen.dart';
import 'create_contract_screen.dart';

class ContractsTab extends StatefulWidget {
  const ContractsTab({super.key});

  @override
  State<ContractsTab> createState() => _ContractsTabState();
}

class _ContractsTabState extends State<ContractsTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ContractStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();

    // Filter contracts based on search and status
    var filteredContracts = appProvider.contracts.where((contract) {
      // Status filter
      if (_statusFilter != null && contract.status != _statusFilter) {
        return false;
      }
      // Search filter: contract number, customer name, product name
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (contract.contractNumber.isNotEmpty &&
                contract.contractNumber.toLowerCase().contains(query)) ||
            contract.customerName.toLowerCase().contains(query) ||
            contract.productName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sort by status (active first, then by percentage)
    filteredContracts.sort((a, b) {
      if (a.status != b.status) {
        if (a.status == ContractStatus.active) return -1;
        if (b.status == ContractStatus.active) return 1;
      }
      return b.paymentPercentage.compareTo(a.paymentPercentage);
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'create_contract_fab',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateContractScreen(),
            ),
          ).then((result) {
            if (result == true && mounted) {
              final agentId = authProvider.user?.id;
              appProvider.loadContracts(agentId: agentId, forceRefresh: true);
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final agentId = authProvider.user?.id;
            await appProvider.loadContracts(agentId: agentId, forceRefresh: true);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Contracts',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search contracts...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Filter Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<ContractStatus?>(
                          icon: Icon(
                            Icons.filter_list,
                            color: _statusFilter != null
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (status) {
                            setState(() {
                              _statusFilter = status;
                            });
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: null,
                              child: Text('All Contracts'),
                            ),
                            const PopupMenuItem(
                              value: ContractStatus.active,
                              child: Text('Active'),
                            ),
                            const PopupMenuItem(
                              value: ContractStatus.completed,
                              child: Text('Completed'),
                            ),
                            const PopupMenuItem(
                              value: ContractStatus.defaulted,
                              child: Text('Defaulted'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary Stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Active',
                        count: appProvider.contracts
                            .where((c) => c.status == ContractStatus.active)
                            .length,
                        color: AppTheme.activeStatus,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Completed',
                        count: appProvider.contracts
                            .where((c) => c.status == ContractStatus.completed)
                            .length,
                        color: AppTheme.completedStatus,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: 'Overdue',
                        count: appProvider.contracts
                            .where((c) => c.isOverdue)
                            .length,
                        color: AppTheme.overdueStatus,
                      ),
                    ],
                  ),
                ),
              ),

              // Contract List
              if (appProvider.isLoadingContracts)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (filteredContracts.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No contracts found'
                                : 'No contracts yet',
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final contract = filteredContracts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ContractCard(
                            contract: contract,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContractDetailScreen(
                                    contract: contract,
                                  ),
                                ),
                              );
                            },
                            onAddPayment: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddPaymentScreen(
                                    contract: contract,
                                  ),
                                ),
                              ).then((result) {
                                if (result == true) {
                                  // Reload data after payment added
                                  final agentId = authProvider.user?.id;
                                  appProvider.loadAllData(agentId: agentId);
                                }
                              });
                            },
                          ),
                        );
                      },
                      childCount: filteredContracts.length,
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

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final Contract contract;
  final VoidCallback? onTap;
  final VoidCallback? onAddPayment;

  const _ContractCard({
    required this.contract,
    this.onTap,
    this.onAddPayment,
  });

  Color _getStatusColor() {
    if (contract.isOverdue) return AppTheme.overdueStatus;
    switch (contract.status) {
      case ContractStatus.active:
        return AppTheme.activeStatus;
      case ContractStatus.completed:
        return AppTheme.completedStatus;
      case ContractStatus.defaulted:
        return AppTheme.overdueStatus;
      case ContractStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusLabel() {
    if (contract.isOverdue) return 'Overdue';
    return contract.status.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final percentage = contract.paymentPercentage.clamp(0, 100);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Contract #, Customer Name and Status
            if (contract.contractNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  contract.contractNumber,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    contract.customerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Product Name
            Text(
              contract.productName,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 12),
            
            // Amount Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(contract.totalAmount),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outstanding',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        currencyFormat.format(contract.outstandingBalance),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: contract.outstandingBalance > 0 
                              ? AppTheme.warningColor 
                              : AppTheme.completedStatus,
                        ),
                      ),
                    ],
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        percentage >= 100
                            ? AppTheme.completedStatus
                            : AppTheme.progressFilled,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            
            // Add Payment Button (only for active contracts)
            if (contract.status == ContractStatus.active) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onAddPayment,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Record Payment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
