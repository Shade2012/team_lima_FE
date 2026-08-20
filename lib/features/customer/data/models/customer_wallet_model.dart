class CustomerWalletModel {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CustomerWalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'IDR',
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerWalletModel.fromJson(Map<String, dynamic> json) {
    return CustomerWalletModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      balance: json['balance'] is num
          ? (json['balance'] as num).toDouble()
          : double.tryParse(json['balance']?.toString() ?? '') ?? 0.0,
      currency: json['currency']?.toString() ?? 'IDR',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}

class CustomerWalletTransactionModel {
  final String id;
  final String walletId;
  final double amount;
  final String type; // TOPUP | PAYMENT | REFUND
  final String? refId;
  final String? note;
  final DateTime? createdAt;

  CustomerWalletTransactionModel({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    this.refId,
    this.note,
    this.createdAt,
  });

  bool get isTopUp => type == 'TOPUP' || amount > 0;

  factory CustomerWalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return CustomerWalletTransactionModel(
      id: json['id']?.toString() ?? '',
      walletId: json['walletId']?.toString() ?? '',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '') ?? 0.0,
      type: json['type']?.toString() ?? 'TOPUP',
      refId: json['refId']?.toString(),
      note: json['note']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}
