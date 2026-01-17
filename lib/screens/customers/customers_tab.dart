import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/customer.dart';
import '../../models/contract.dart';
import 'customer_detail_screen.dart';
import 'add_customer_screen.dart';

class CustomersTab extends StatefulWidget {
  const CustomersTab({super.key});

  @override
  State<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends State<CustomersTab> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'recent', 'contracts'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filterAndSortCustomers(List<Customer> customers) {
    // Filter by search
    var filtered = customers.where((customer) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return customer.fullName.toLowerCase().contains(query) ||
          customer.phoneNumber.toLowerCase().contains(query) ||
          (customer.customerNumber?.toLowerCase().contains(query) ?? false);
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'recent':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'contracts':
        filtered.sort((a, b) => b.contractCount.compareTo(a.contractCount));
        break;
    }

    return filtered;
  }

  Contract? _getActiveContract(AppProvider appProvider, int customerId) {
    try {
      return appProvider.contracts.firstWhere(
        (c) => c.customerId == customerId && c.status == ContractStatus.active,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final appProvider = context.watch<AppProvider>();
    final filteredCustomers = _filterAndSortCustomers(appProvider.customers);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddCustomerScreen(),
            ),
          ).then((result) {
            if (result == true) {
              // Reload customers after adding new one
              final agentId = authProvider.user?.id;
              appProvider.loadCustomers(agentId: agentId);
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Add Customer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Customers',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${filteredCustomers.length} total',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar and Sort
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
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
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
                      
                      // Sort Button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.sort, color: AppTheme.textSecondary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            setState(() {
                              _sortBy = value;
                            });
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'name',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort_by_alpha,
                                    color: _sortBy == 'name' 
                                        ? AppTheme.primaryColor 
                                        : AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'By Name',
                                    style: TextStyle(
                                      color: _sortBy == 'name' 
                                          ? AppTheme.primaryColor 
                                          : AppTheme.textPrimary,
                                      fontWeight: _sortBy == 'name' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'recent',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: _sortBy == 'recent' 
                                        ? AppTheme.primaryColor 
                                        : AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Most Recent',
                                    style: TextStyle(
                                      color: _sortBy == 'recent' 
                                          ? AppTheme.primaryColor 
                                          : AppTheme.textPrimary,
                                      fontWeight: _sortBy == 'recent' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'contracts',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.description,
                                    color: _sortBy == 'contracts' 
                                        ? AppTheme.primaryColor 
                                        : AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'By Contracts',
                                    style: TextStyle(
                                      color: _sortBy == 'contracts' 
                                          ? AppTheme.primaryColor 
                                          : AppTheme.textPrimary,
                                      fontWeight: _sortBy == 'contracts' 
                                          ? FontWeight.w600 
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Customer List
              if (appProvider.isLoadingCustomers)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (filteredCustomers.isEmpty)
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
                          if (_searchQuery.isEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to add your first customer',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textHint,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                        final customer = filteredCustomers[index];
                        final activeContract = _getActiveContract(appProvider, customer.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CustomerCard(
                            customer: customer,
                            activeContract: activeContract,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CustomerDetailScreen(
                                    customerId: customer.id,
                                    customerName: customer.fullName,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      childCount: filteredCustomers.length,
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

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final Contract? activeContract;
  final VoidCallback? onTap;

  const _CustomerCard({
    required this.customer,
    this.activeContract,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  customer.fullName.isNotEmpty 
                      ? customer.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.fullName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    customer.phoneNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (activeContract != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        activeContract!.productName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (activeContract!.paymentPercentage / 100).clamp(0.0, 1.0),
                              backgroundColor: AppTheme.progressBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                activeContract!.paymentPercentage >= 100
                                    ? AppTheme.completedStatus
                                    : AppTheme.progressFilled,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${activeContract!.paymentPercentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: activeContract!.paymentPercentage >= 75
                                ? AppTheme.completedStatus
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Text(
                      'Added ${dateFormat.format(customer.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
