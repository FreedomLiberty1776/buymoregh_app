import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/contract.dart';
import '../../widgets/customer_contract_card.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
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
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return contract.customerName.toLowerCase().contains(query) ||
            contract.productName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    // Sort by status (overdue first, then active, then completed)
    filteredContracts.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return a.status.index.compareTo(b.status.index);
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final agentId = authProvider.user?.id;
            await appProvider.loadContracts(agentId: agentId);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Customers',
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
                            hintText: 'Search customers...',
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
                              child: Text('All Status'),
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
                              child: Text('Overdue'),
                            ),
                          ],
                        ),
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
                            Icons.people_outline,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No customers found'
                                : 'No customers yet',
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final contract = filteredContracts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CustomerContractCard(contract: contract),
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
