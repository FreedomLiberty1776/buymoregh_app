/// Hire Purchase Contract model for BuyMore Agent App

enum ContractStatus {
  active,
  completed,
  defaulted,
  cancelled;
  
  String get displayName {
    switch (this) {
      case ContractStatus.active:
        return 'Active';
      case ContractStatus.completed:
        return 'Completed';
      case ContractStatus.defaulted:
        return 'Defaulted';
      case ContractStatus.cancelled:
        return 'Cancelled';
    }
  }
  
  static ContractStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return ContractStatus.active;
      case 'COMPLETED':
        return ContractStatus.completed;
      case 'DEFAULTED':
        return ContractStatus.defaulted;
      case 'CANCELLED':
        return ContractStatus.cancelled;
      default:
        return ContractStatus.active;
    }
  }
}

class Contract {
  final int id;
  final String contractNumber;
  final int customerId;
  final String customerName;
  final int productId;
  final String productName;
  final int? agentId;
  final double totalAmount;
  final double downPayment;
  final double totalPaid;
  final double outstandingBalance;
  final double paymentPercentage;
  final int durationMonths;
  final double interestRate;
  final ContractStatus status;
  final bool productDelivered;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? nextPaymentDate;
  final double monthlyInstallment;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Sync tracking
  final bool isSynced;
  final String? localUniqueId;

  Contract({
    required this.id,
    this.contractNumber = '',
    required this.customerId,
    required this.customerName,
    required this.productId,
    required this.productName,
    this.agentId,
    required this.totalAmount,
    required this.downPayment,
    required this.totalPaid,
    required this.outstandingBalance,
    required this.paymentPercentage,
    required this.durationMonths,
    required this.interestRate,
    required this.status,
    this.productDelivered = false,
    required this.startDate,
    required this.endDate,
    this.nextPaymentDate,
    required this.monthlyInstallment,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = true,
    this.localUniqueId,
  });

  bool get isOverdue {
    if (status != ContractStatus.active) return false;
    if (nextPaymentDate == null) return false;
    return DateTime.now().isAfter(nextPaymentDate!);
  }

  factory Contract.fromJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      contractNumber: json['contract_number']?.toString() ?? '',
      customerId: json['customer'] ?? json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      productId: json['product'] ?? json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      agentId: json['agent'] ?? json['agent_id'],
      totalAmount: _parseDouble(json['total_amount']),
      downPayment: _parseDouble(json['down_payment']),
      totalPaid: _parseDouble(json['total_paid']),
      outstandingBalance: _parseDouble(json['outstanding_balance']),
      paymentPercentage: _parseDouble(json['payment_percentage']),
      durationMonths: json['duration_months'] ?? 0,
      interestRate: _parseDouble(json['interest_rate']),
      status: ContractStatus.fromString(json['status'] ?? 'ACTIVE'),
      productDelivered: json['product_delivered'] == true,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : DateTime.now().add(const Duration(days: 365)),
      nextPaymentDate: json['next_payment_date'] != null 
          ? DateTime.parse(json['next_payment_date']) 
          : null,
      monthlyInstallment: _parseDouble(json['monthly_installment']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer': customerId,
      'customer_name': customerName,
      'product': productId,
      'product_name': productName,
      'agent': agentId,
      'total_amount': totalAmount.toString(),
      'down_payment': downPayment.toString(),
      'total_paid': totalPaid.toString(),
      'outstanding_balance': outstandingBalance.toString(),
      'payment_percentage': paymentPercentage.toString(),
      'duration_months': durationMonths,
      'interest_rate': interestRate.toString(),
      'status': status.name.toUpperCase(),
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'next_payment_date': nextPaymentDate?.toIso8601String().split('T')[0],
      'monthly_installment': monthlyInstallment.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'contract_number': contractNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'product_id': productId,
      'product_name': productName,
      'agent_id': agentId,
      'total_amount': totalAmount,
      'down_payment': downPayment,
      'total_paid': totalPaid,
      'outstanding_balance': outstandingBalance,
      'payment_percentage': paymentPercentage,
      'duration_months': durationMonths,
      'interest_rate': interestRate,
      'status': status.name.toUpperCase(),
      'product_delivered': productDelivered ? 1 : 0,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'next_payment_date': nextPaymentDate?.toIso8601String(),
      'monthly_installment': monthlyInstallment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'local_unique_id': localUniqueId,
    };
  }

  factory Contract.fromLocalJson(Map<String, dynamic> json) {
    return Contract(
      id: json['id'] ?? 0,
      contractNumber: json['contract_number']?.toString() ?? '',
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? '',
      agentId: json['agent_id'],
      totalAmount: _parseDouble(json['total_amount']),
      downPayment: _parseDouble(json['down_payment']),
      totalPaid: _parseDouble(json['total_paid']),
      outstandingBalance: _parseDouble(json['outstanding_balance']),
      paymentPercentage: _parseDouble(json['payment_percentage']),
      durationMonths: json['duration_months'] ?? 0,
      interestRate: _parseDouble(json['interest_rate']),
      status: ContractStatus.fromString(json['status'] ?? 'ACTIVE'),
      productDelivered: json['product_delivered'] == 1,
      startDate: json['start_date'] != null 
          ? DateTime.parse(json['start_date']) 
          : DateTime.now(),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date']) 
          : DateTime.now().add(const Duration(days: 365)),
      nextPaymentDate: json['next_payment_date'] != null 
          ? DateTime.parse(json['next_payment_date']) 
          : null,
      monthlyInstallment: _parseDouble(json['monthly_installment']),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      isSynced: json['is_synced'] == 1,
      localUniqueId: json['local_unique_id'],
    );
  }
}
