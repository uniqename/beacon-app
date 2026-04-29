enum DonationStatus { pending, completed, failed, refunded }

enum DonationFrequency { oneTime, monthly }

enum PaymentMethod { card, momo, paypal, bankTransfer, applePay, googlePay }

enum PaymentGateway { flutterwave, paystack, paypal, square }

class Donation {
  final String id;
  final String? userId;
  final String? divisionId;
  final double amount;
  final String currency; // 'USD' or 'GHS'
  final DonationFrequency frequency;
  final PaymentMethod paymentMethod;
  final PaymentGateway? paymentGateway;
  final String? transactionId;
  final DonationStatus status;
  final String? donorName;
  final String? donorEmail;
  final String? donorPhone;
  final bool isAnonymous;
  final bool isRecurring;
  final DateTime? nextBillingDate;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;

  const Donation({
    required this.id,
    this.userId,
    this.divisionId,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.paymentMethod,
    this.paymentGateway,
    this.transactionId,
    this.status = DonationStatus.pending,
    this.donorName,
    this.donorEmail,
    this.donorPhone,
    this.isAnonymous = false,
    this.isRecurring = false,
    this.nextBillingDate,
    required this.createdAt,
    this.completedAt,
    this.receiptUrl,
    this.metadata,
  });

  factory Donation.fromMap(Map<String, dynamic> map) {
    return Donation(
      id: map['id'] as String,
      userId: map['user_id'] as String?,
      divisionId: map['division_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      frequency: DonationFrequency.values.firstWhere(
        (e) => e.toString().split('.').last == map['frequency'],
        orElse: () => DonationFrequency.oneTime,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['payment_method'],
        orElse: () => PaymentMethod.card,
      ),
      paymentGateway: map['payment_gateway'] != null
          ? PaymentGateway.values.firstWhere(
              (e) => e.toString().split('.').last == map['payment_gateway'],
              orElse: () => PaymentGateway.flutterwave,
            )
          : null,
      transactionId: map['transaction_id'] as String?,
      status: DonationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => DonationStatus.pending,
      ),
      donorName: map['donor_name'] as String?,
      donorEmail: map['donor_email'] as String?,
      donorPhone: map['donor_phone'] as String?,
      isAnonymous: map['is_anonymous'] == 1,
      isRecurring: map['is_recurring'] == 1,
      nextBillingDate: map['next_billing_date'] != null
          ? DateTime.parse(map['next_billing_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      receiptUrl: map['receipt_url'] as String?,
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'division_id': divisionId,
      'amount': amount,
      'currency': currency,
      'frequency': frequency.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last,
      'payment_gateway': paymentGateway?.toString().split('.').last,
      'transaction_id': transactionId,
      'status': status.toString().split('.').last,
      'donor_name': donorName,
      'donor_email': donorEmail,
      'donor_phone': donorPhone,
      'is_anonymous': isAnonymous ? 1 : 0,
      'is_recurring': isRecurring ? 1 : 0,
      'next_billing_date': nextBillingDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'receipt_url': receiptUrl,
      'metadata': metadata,
    };
  }

  Donation copyWith({
    String? id,
    String? userId,
    String? divisionId,
    double? amount,
    String? currency,
    DonationFrequency? frequency,
    PaymentMethod? paymentMethod,
    PaymentGateway? paymentGateway,
    String? transactionId,
    DonationStatus? status,
    String? donorName,
    String? donorEmail,
    String? donorPhone,
    bool? isAnonymous,
    bool? isRecurring,
    DateTime? nextBillingDate,
    DateTime? createdAt,
    DateTime? completedAt,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
  }) {
    return Donation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      divisionId: divisionId ?? this.divisionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      transactionId: transactionId ?? this.transactionId,
      status: status ?? this.status,
      donorName: donorName ?? this.donorName,
      donorEmail: donorEmail ?? this.donorEmail,
      donorPhone: donorPhone ?? this.donorPhone,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      isRecurring: isRecurring ?? this.isRecurring,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper method to get currency symbol
  String get currencySymbol => currency == 'USD' ? '\$' : '₵';

  // Helper method to format amount with currency
  String get formattedAmount => '$currencySymbol${amount.toStringAsFixed(2)}';

  // Helper method to check if donation is complete
  bool get isCompleted => status == DonationStatus.completed;

  // Helper method to check if donation is pending
  bool get isPending => status == DonationStatus.pending;

  // Helper method to check if donation failed
  bool get isFailed => status == DonationStatus.failed;
}
