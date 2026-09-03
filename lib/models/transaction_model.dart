enum TransactionStatus { completed, processing, pending, rejected }
enum CurrencyType { bdt, usd }

class PayoutTransaction {
  final String id;
  final double amount;
  final CurrencyType currency;
  final int tapsDeducted;
  final String method; // 'bKash', 'Nagad', 'Bank Payment', 'PayPal'
  final String accountName;
  final String destination;
  final TransactionStatus status;
  final DateTime timestamp;

  const PayoutTransaction({
    required this.id,
    required this.amount,
    this.currency = CurrencyType.bdt,
    required this.tapsDeducted,
    required this.method,
    this.accountName = '',
    required this.destination,
    required this.status,
    required this.timestamp,
  });

  String get formattedAmount {
    return currency == CurrencyType.bdt
        ? '৳${amount.toStringAsFixed(2)}'
        : '\$${amount.toStringAsFixed(2)}';
  }
}
