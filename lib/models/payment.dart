/// Payment model for BuyMore Agent App

enum PaymentApprovalStatus {
  pending,
  approved,
  rejected;
  
  String get displayName {
    switch (this) {
      case PaymentApprovalStatus.pending:
        return 'Pending';
      case PaymentApprovalStatus.approved:
        return 'Approved';
      case PaymentApprovalStatus.rejected:
        return 'Rejected';
    }
  }
  
  static PaymentApprovalStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING':
        return PaymentApprovalStatus.pending;
      case 'APPROVED':
        return PaymentApprovalStatus.approved;
      case 'REJECTED':
        return PaymentApprovalStatus.rejected;
      default:
        return PaymentApprovalStatus.pending;
    }
  }
}

enum PaymentMethod {
  cash,
  mobileMoney,
  bankTransfer;
  
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.mobileMoney:
        return 'Mobile Money';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
  
  static PaymentMethod fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CASH':
        return PaymentMethod.cash;
      case 'MOBILE_MONEY':
      case 'MOMO':
        return PaymentMethod.mobileMoney;
      case 'BANK_TRANSFER':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.cash;
    }
  }
}

class Payment {
  final int id;
  final int contractId;
  final int customerId;
  final String customerName;
  final String? customerPhone;
  final int? agentId;
  final String? agentName;
  final double amount;
  final PaymentMethod paymentMethod;
  final String? momoPhone;
  final PaymentApprovalStatus approvalStatus;
  final String? rejectionReason;
  final DateTime? approvedAt;
  final int? approvedBy;
  final String? clientReference;
  final String? paystackReference;
  final String? paystackStatus;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  
  // Product info
  final String? productName;
  final int? productId;
  
  // For display purposes
  final double? contractTotalAmount;
  final double? contractOutstandingBalance;
  final double? contractTotalPaid;
  final double? contractPaymentPercentage;
  final double? balanceBefore;
  final double? balanceAfter;
  
  // Sync tracking
  final bool isSynced;
  final String? localUniqueId;

  Payment({
    required this.id,
    required this.contractId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    this.agentId,
    this.agentName,
    required this.amount,
    required this.paymentMethod,
    this.momoPhone,
    required this.approvalStatus,
    this.rejectionReason,
    this.approvedAt,
    this.approvedBy,
    this.clientReference,
    this.paystackReference,
    this.paystackStatus,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.productName,
    this.productId,
    this.contractTotalAmount,
    this.contractOutstandingBalance,
    this.contractTotalPaid,
    this.contractPaymentPercentage,
    this.balanceBefore,
    this.balanceAfter,
    this.isSynced = true,
    this.localUniqueId,
  });

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      contractId: json['contract'] ?? json['contract_id'] ?? 0,
      customerId: json['customer'] ?? json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'],
      agentId: json['agent'] ?? json['agent_id'],
      agentName: json['agent_name'],
      amount: _parseDouble(json['amount']),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'CASH'),
      momoPhone: json['momo_phone'],
      approvalStatus: PaymentApprovalStatus.fromString(json['approval_status'] ?? 'PENDING'),
      rejectionReason: json['rejection_reason'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      approvedBy: json['approved_by'],
      clientReference: json['client_reference'],
      paystackReference: json['paystack_reference'],
      paystackStatus: json['paystack_status'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : (json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : DateTime.now()),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      notes: json['notes'],
      productName: json['product_name'],
      productId: json['product_id'],
      contractTotalAmount: _parseDouble(json['contract_total_amount']),
      contractOutstandingBalance: _parseDouble(json['contract_outstanding_balance']),
      contractTotalPaid: _parseDouble(json['contract_total_paid']),
      contractPaymentPercentage: _parseDouble(json['contract_payment_percentage']),
      balanceBefore: _parseDouble(json['balance_before']),
      balanceAfter: _parseDouble(json['balance_after']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract': contractId,
      'customer': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'agent': agentId,
      'agent_name': agentName,
      'amount': amount.toString(),
      'payment_method': paymentMethod.name.toUpperCase(),
      'momo_phone': momoPhone,
      'approval_status': approvalStatus.name.toUpperCase(),
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'client_reference': clientReference,
      'paystack_reference': paystackReference,
      'paystack_status': paystackStatus,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'product_name': productName,
      'product_id': productId,
    };
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'agent_id': agentId,
      'agent_name': agentName,
      'amount': amount,
      'payment_method': paymentMethod.name.toUpperCase(),
      'momo_phone': momoPhone,
      'approval_status': approvalStatus.name.toUpperCase(),
      'rejection_reason': rejectionReason,
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'client_reference': clientReference,
      'paystack_reference': paystackReference,
      'paystack_status': paystackStatus,
      'payment_date': paymentDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'notes': notes,
      'product_name': productName,
      'product_id': productId,
      'contract_total_amount': contractTotalAmount,
      'contract_outstanding_balance': contractOutstandingBalance,
      'contract_total_paid': contractTotalPaid,
      'contract_payment_percentage': contractPaymentPercentage,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'is_synced': isSynced ? 1 : 0,
      'local_unique_id': localUniqueId,
    };
  }

  factory Payment.fromLocalJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      contractId: json['contract_id'] ?? 0,
      customerId: json['customer_id'] ?? 0,
      customerName: json['customer_name'] ?? '',
      customerPhone: json['customer_phone'],
      agentId: json['agent_id'],
      agentName: json['agent_name'],
      amount: _parseDouble(json['amount']),
      paymentMethod: PaymentMethod.fromString(json['payment_method'] ?? 'CASH'),
      momoPhone: json['momo_phone'],
      approvalStatus: PaymentApprovalStatus.fromString(json['approval_status'] ?? 'PENDING'),
      rejectionReason: json['rejection_reason'],
      approvedAt: json['approved_at'] != null 
          ? DateTime.parse(json['approved_at']) 
          : null,
      approvedBy: json['approved_by'],
      clientReference: json['client_reference'],
      paystackReference: json['paystack_reference'],
      paystackStatus: json['paystack_status'],
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : DateTime.now(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
      notes: json['notes'],
      productName: json['product_name'],
      productId: json['product_id'],
      contractTotalAmount: _parseDouble(json['contract_total_amount']),
      contractOutstandingBalance: _parseDouble(json['contract_outstanding_balance']),
      contractTotalPaid: _parseDouble(json['contract_total_paid']),
      contractPaymentPercentage: _parseDouble(json['contract_payment_percentage']),
      balanceBefore: _parseDouble(json['balance_before']),
      balanceAfter: _parseDouble(json['balance_after']),
      isSynced: json['is_synced'] == 1,
      localUniqueId: json['local_unique_id'],
    );
  }
}
