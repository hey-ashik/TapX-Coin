import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../services/api_service.dart';

class WalletProvider extends ChangeNotifier {
  static const String _keyWalletBalance = 'tapx_wallet_redeemable_taps';

  // Store internal balance in redeemable tap credits:
  // Conversion formula:
  // 10,000 taps = ৳10 BDT (1,000 taps = ৳1.00 BDT)
  // 100,000 taps = $1.00 USD
  int _tapsBalance = 0;
  CurrencyType _currency = CurrencyType.bdt;
  final List<PayoutTransaction> _transactions = [];
  bool _isLoadingTransactions = false;
  Timer? _pollingTimer;

  WalletProvider() {
    _restoreWalletState();
    fetchTransactions();
    _startPolling();
  }

  int get tapsBalance => _tapsBalance;
  CurrencyType get currency => _currency;
  List<PayoutTransaction> get transactions => List.unmodifiable(_transactions);
  bool get isLoadingTransactions => _isLoadingTransactions;

  String get currencySymbol => _currency == CurrencyType.bdt ? '৳' : '\$';
  String get currencyCode => _currency == CurrencyType.bdt ? 'BDT' : 'USDT';

  // Dynamic balance calculated from actual redeemable taps
  double get balance {
    if (_currency == CurrencyType.bdt) {
      return _tapsBalance / 1000.0; // 1,000 taps = ৳1.00 BDT
    } else {
      return _tapsBalance / 100000.0; // 100,000 taps = $1.00 USDT
    }
  }

  String get conversionRateText {
    if (_currency == CurrencyType.bdt) {
      return 'Rate: 10,000 taps = ৳10 BDT';
    } else {
      return 'Rate: 100,000 taps = \$1.00 USDT';
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (ApiService.hasToken) {
        fetchTransactions();
      }
    });
  }

  Future<void> _restoreWalletState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _tapsBalance = prefs.getInt(_keyWalletBalance) ?? _tapsBalance;
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Wallet restore note: $e');
    }
  }

  Future<void> _persistWalletState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWalletBalance, _tapsBalance);
    } catch (e) {
      debugPrint('Wallet persist note: $e');
    }
  }

  void resetForGuest() {
    _tapsBalance = 0;
    _transactions.clear();
    _persistWalletState();
    notifyListeners();
  }

  void loadForUser(int userScore) {
    _tapsBalance = userScore;
    _persistWalletState();
    fetchTransactions();
    notifyListeners();
  }

  void clearSession() {
    _tapsBalance = 0;
    _transactions.clear();
    _persistWalletState();
    notifyListeners();
  }

  void syncWithTapScore(int lifetimeScore) {
    if (_tapsBalance == 0 && lifetimeScore > 0) {
      _tapsBalance = lifetimeScore;
      _persistWalletState();
      notifyListeners();
    }
  }

  void addTaps(int points) {
    _tapsBalance += points;
    _persistWalletState();
    notifyListeners();
  }

  void toggleCurrency() {
    _currency = _currency == CurrencyType.bdt ? CurrencyType.usd : CurrencyType.bdt;
    notifyListeners();
  }

  void setCurrency(CurrencyType type) {
    _currency = type;
    notifyListeners();
  }

  // Milestone target (৳500 or $50)
  double get milestoneTarget => _currency == CurrencyType.bdt ? 500.0 : 50.0;

  double get milestoneProgress {
    if (milestoneTarget <= 0) return 0.0;
    final progress = balance / milestoneTarget;
    return progress.clamp(0.0, 1.0);
  }

  bool isTierUnlocked(double tierAmount) {
    return balance >= tierAmount;
  }

  Future<void> fetchTransactions() async {
    if (!ApiService.hasToken) return;
    _isLoadingTransactions = true;
    notifyListeners();
    try {
      final data = await ApiService.getTransactions();
      if (data != null) {
        _transactions.clear();
        for (final item in data) {
          TransactionStatus status = TransactionStatus.processing;
          final statusStr = (item['status'] ?? '').toString().toLowerCase();
          if (statusStr == 'completed') {
            status = TransactionStatus.completed;
          } else if (statusStr == 'rejected') {
            status = TransactionStatus.rejected;
          }

          final currencyStr = (item['currency'] ?? 'bdt').toString().toLowerCase();
          final curr = currencyStr == 'usd' ? CurrencyType.usd : CurrencyType.bdt;

          DateTime ts = DateTime.now();
          if (item['created_at'] != null) {
            ts = DateTime.tryParse(item['created_at'].toString()) ?? ts;
          }

          _transactions.add(
            PayoutTransaction(
              id: item['id'] ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0.0,
              currency: curr,
              tapsDeducted: (item['taps_deducted'] as num?)?.toInt() ?? 0,
              method: item['method'] ?? 'bKash',
              accountName: item['account_name'] ?? '',
              destination: item['destination'] ?? '',
              status: status,
              timestamp: ts,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('fetchTransactions note: $e');
    } finally {
      _isLoadingTransactions = false;
      _safeNotifyListeners();
    }
  }

  bool requestPayout({
    required double amount,
    required String method,
    required String accountName,
    required String destination,
  }) {
    if (amount <= 0 || amount > balance) {
      return false;
    }

    final int tapsDeducted = _currency == CurrencyType.bdt
        ? (amount * 1000).toInt()
        : (amount * 100000).toInt();

    // Deduct redeemable wallet balance ONLY (Lifetime Score remains untouched)
    _tapsBalance = (_tapsBalance - tapsDeducted).clamp(0, 999999999);
    _persistWalletState();

    final txId = 'TX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final newTx = PayoutTransaction(
      id: txId,
      amount: amount,
      currency: _currency,
      tapsDeducted: tapsDeducted,
      method: method,
      accountName: accountName,
      destination: destination,
      status: TransactionStatus.processing,
      timestamp: DateTime.now(),
    );

    _transactions.insert(0, newTx);

    // Dispatch to backend API
    ApiService.requestPayout(
      amount: amount,
      currency: _currency == CurrencyType.bdt ? 'bdt' : 'usd',
      method: method,
      accountName: accountName,
      destination: destination,
    );

    notifyListeners();
    return true;
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}
