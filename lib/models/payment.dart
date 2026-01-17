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
  final int? agentId;
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
  
  // For display purposes
  final double? contractOutstandingBalance;
  final double? contractTotalPaid;
  final double? contractPaymentPercentage;
  
  // Sync tracking
  final bool isSynced;
  final String? localUniqueId;

  Payment({
    required this.id,
    required this.contractId,
    required this.customerId,
    required this.customerName,
    this.agentId,
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
    this.contractOutstandingBalance,
    this.contractTotalPaid,
    this.contractPaymentPercentage,
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
      agentId: json['agent'] ?? json['agent_id'],
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
      contractOutstandingBalance: _parseDouble(json['contract_outstanding_balance']),
      contractTotalPaid: _parseDouble(json['contract_total_paid']),
      contractPaymentPercentage: _parseDouble(json['contract_payment_percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contract': contractId,
      'customer': customerId,
      'customer_name': customerName,
      'agent': agentId,
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
    };
  }

  /// For local database storage
  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'contract_id': contractId,
      'customer_id': customerId,
      'customer_name': customerName,
      'agent_id': agentId,
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
      'contract_outstanding_balance': contractOutstandingBalance,
      'contract_total_paid': contractTotalPaid,
      'contract_payment_percentage': contractPaymentPercentage,
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
      agentId: json['agent_id'],
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
      contractOutstandingBalance: _parseDouble(json['contract_outstanding_balance']),
      contractTotalPaid: _parseDouble(json['contract_total_paid']),
      contractPaymentPercentage: _parseDouble(json['contract_payment_percentage']),
      isSynced: json['is_synced'] == 1,
      localUniqueId: json['local_unique_id'],
    );
  }
}
