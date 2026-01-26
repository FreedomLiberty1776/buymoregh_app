import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/customer.dart';
import '../../models/contract.dart';
import '../../models/payment.dart';
import '../../services/api_service.dart';
import '../contracts/add_payment_screen.dart';
import '../contracts/contract_detail_screen.dart';
import '../payments/payment_detail_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  final String customerName;

  const CustomerDetailScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
  List<Contract> _contracts = [];
  List<Payment> _recentPayments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final appProvider = context.read<AppProvider>();
    final authProvider = context.read<AuthProvider>();
    final api = ApiService();
    
    setState(() => _isLoading = true);
    
    // Initialize with placeholder customer
    _customer = Customer(
      id: widget.customerId,
      fullName: widget.customerName,
      phoneNumber: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _contracts = [];
    _recentPayments = [];
    
    // Always try API first when online
    try {
      // Fetch customer details
      final customerResponse = await api.getCustomer(widget.customerId);
      if (customerResponse.success && customerResponse.data != null) {
        _customer = customerResponse.data!;
      }
      
      // Fetch contracts for this specific customer from API
      final contractsResponse = await api.getContractsForCustomer(widget.customerId);
      if (contractsResponse.success && contractsResponse.data != null) {
        _contracts = contractsResponse.data!;
      }
      
      // Fetch payments for this specific customer from API
      final paymentsResponse = await api.getPaymentsForCustomer(widget.customerId);
      if (paymentsResponse.success && paymentsResponse.data != null) {
        _recentPayments = paymentsResponse.data!.take(10).toList();
      }
    } catch (e) {
      // If API fails, fall back to cached data
      _customer = appProvider.customers.firstWhere(
        (c) => c.id == widget.customerId,
        orElse: () => Customer(
          id: widget.customerId,
          fullName: widget.customerName,
          phoneNumber: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      
      _contracts = appProvider.contracts
          .where((c) => c.customerId == widget.customerId)
          .toList();
      
      _recentPayments = appProvider.payments
          .where((p) => p.customerId == widget.customerId)
          .take(10)
          .toList();
    }
    
    setState(() => _isLoading = false);
    
    // Refresh all data in the background
    final agentId = authProvider.user?.id;
    appProvider.loadAllData(agentId: agentId, forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {                       
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.customerName,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.textPrimary),
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditCustomerScreen(
                    customerId: widget.customerId,
                    customerName: widget.customerName,
                  ),
                ),
              );
              if (updated == true && mounted) {
                _loadCustomerData();
              }
            },
            tooltip: 'Edit customer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCustomerData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Info Card
                      _buildCustomerInfoCard(context),
                      
                      const SizedBox(height: 24),
                      
                      // Contracts Section
                      Text(
                        'Contracts',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_contracts.isEmpty)
                        _buildEmptyState(
                          icon: Icons.description_outlined,
                          message: 'No contracts found',
                        )
                      else
                        ..._contracts.map((contract) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildContractCard(context, contract, currencyFormat),
                        )),
                      
                      const SizedBox(height: 24),
                      
                      // Recent Payments Section
                      Text(
                        'Recent Payments',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (_recentPayments.isEmpty)
                        _buildEmptyState(
                          icon: Icons.receipt_long_outlined,
                          message: 'No payments yet',
                        )
                      else
                        ..._recentPayments.map((payment) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildPaymentItem(context, payment, currencyFormat, dateFormat, onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentDetailScreen(payment: payment),
                              ),
                            );
                          }),
                        )),
                      
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context) {
    if (_customer == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar and Name
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    _customer!.fullName.isNotEmpty 
                        ? _customer!.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _customer!.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_customer!.customerNumber != null)
                      Text(
                        _customer!.customerNumber!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Contact Info
          _buildInfoRow(Icons.phone, _customer!.phoneNumber, context),
          if (_customer!.email != null && _customer!.email!.isNotEmpty)
            _buildInfoRow(Icons.email, _customer!.email!, context),
          if (_customer!.address != null && _customer!.address!.isNotEmpty)
            _buildInfoRow(Icons.location_on, _customer!.address!, context),
          if (_customer!.city != null && _customer!.city!.isNotEmpty)
            _buildInfoRow(
              Icons.place, 
              '${_customer!.city}${_customer!.region != null ? ', ${_customer!.region}' : ''}',
              context,
            ),
          
          // Employment Info
          if (_customer!.occupation != null && _customer!.occupation!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildInfoRow(Icons.work, _customer!.occupation!, context),
            if (_customer!.workplace != null && _customer!.workplace!.isNotEmpty)
              _buildInfoRow(Icons.business, _customer!.workplace!, context),
          ],
          
          // Next of Kin
          if (_customer!.nextOfKinName != null && _customer!.nextOfKinName!.isNotEmpty) ...[
            const Divider(height: 24),
            Text(
              'Next of Kin',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person, _customer!.nextOfKinName!, context),
            if (_customer!.nextOfKinPhone != null && _customer!.nextOfKinPhone!.isNotEmpty)
              _buildInfoRow(Icons.phone, _customer!.nextOfKinPhone!, context),
            if (_customer!.nextOfKinRelationship != null && _customer!.nextOfKinRelationship!.isNotEmpty)
              _buildInfoRow(Icons.family_restroom, _customer!.nextOfKinRelationship!, context),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(
    BuildContext context,
    Contract contract,
    NumberFormat currencyFormat,
  ) {
    final percentage = contract.paymentPercentage.clamp(0, 100);
    final statusColor = _getContractStatusColor(contract);
    final authProvider = context.read<AuthProvider>();
    final appProvider = context.read<AppProvider>();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContractDetailScreen(contract: contract),
          ),
        ).then((_) => _loadCustomerData());
      },
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
          // Product and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  contract.productName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  contract.isOverdue ? 'Overdue' : contract.status.displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Amounts
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    currencyFormat.format(contract.totalAmount),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Paid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    currencyFormat.format(contract.totalPaid),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.completedStatus,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      currencyFormat.format(contract.outstandingBalance),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: contract.outstandingBalance > 0
                            ? AppTheme.warningColor
                            : AppTheme.completedStatus,
                      ),
                    ),
                  ],
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
                ),
              ),
            ],
          ),
          
          // Add Payment Button
          if (contract.status == ContractStatus.active) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPaymentScreen(contract: contract),
                    ),
                  ).then((result) {
                    if (result == true) {
                      final agentId = authProvider.user?.id;
                      appProvider.loadAllData(agentId: agentId);
                      _loadCustomerData();
                    }
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildPaymentItem(
    BuildContext context,
    Payment payment,
    NumberFormat currencyFormat,
    DateFormat dateFormat, {
    VoidCallback? onTap,
  }) {
    Color statusColor;
    switch (payment.approvalStatus) {
      case PaymentApprovalStatus.approved:
        statusColor = AppTheme.completedStatus;
        break;
      case PaymentApprovalStatus.pending:
        statusColor = AppTheme.warningColor;
        break;
      case PaymentApprovalStatus.rejected:
        statusColor = AppTheme.errorColor;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                payment.paymentMethod == PaymentMethod.mobileMoney
                    ? Icons.phone_android
                    : Icons.payments,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currencyFormat.format(payment.amount),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Show product name if available
                  if (payment.productName != null && payment.productName!.isNotEmpty) ...[
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
                  Text(
                    '${dateFormat.format(payment.paymentDate)} • ${payment.paymentMethod.displayName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTheme.textHint),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Color _getContractStatusColor(Contract contract) {
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
}
