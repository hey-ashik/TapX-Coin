import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/wallet_provider.dart';
import '../services/haptic_service.dart';
import '../theme/app_colors.dart';
import 'app_toast.dart';
import 'payout_confirmation_sheet.dart';

class WithdrawalModal extends StatefulWidget {
  const WithdrawalModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99000000),
      builder: (context) => const WithdrawalModal(),
    );
  }

  @override
  State<WithdrawalModal> createState() => _WithdrawalModalState();
}

class _WithdrawalModalState extends State<WithdrawalModal> {
  late TextEditingController _amountController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();

  late String _selectedMethod;

  List<String> _getMethodsForCurrency(CurrencyType currency) {
    if (currency == CurrencyType.usd) {
      return [
        'USDT (TRC20)',
        'Binance Pay (UID / Email)',
        'USDT (BEP20)',
        'PayPal',
        'Bank Payment',
      ];
    }
    return [
      'bKash',
      'Nagad',
      'Bank Payment',
      'PayPal',
    ];
  }

  @override
  void initState() {
    super.initState();
    final wallet = context.read<WalletProvider>();
    final initialAmount = wallet.currency == CurrencyType.bdt ? '100' : '10';
    _amountController = TextEditingController(text: initialAmount);
    _selectedMethod = wallet.currency == CurrencyType.bdt ? 'bKash' : 'USDT (TRC20)';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _destinationController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  List<double> _getPresetAmounts(CurrencyType currency) {
    return currency == CurrencyType.bdt
        ? [50.0, 100.0, 250.0, 500.0]
        : [5.0, 10.0, 25.0, 50.0];
  }

  void _handleProcess() {
    HapticService.mediumImpact();
    final wallet = context.read<WalletProvider>();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final name = _nameController.text.trim();
    String destination = _destinationController.text.trim();

    if (amount <= 0) {
      _showError('Please enter a valid payout amount.');
      return;
    }

    if (amount > wallet.balance) {
      _showError('Insufficient balance for ${wallet.currencySymbol}${amount.toStringAsFixed(2)} withdrawal.');
      return;
    }

    if (name.isEmpty) {
      _showError('Please enter account holder name.');
      return;
    }

    // Name must only contain letters and spaces
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
      _showError('Account holder name must contain only letters and spaces.');
      return;
    }

    if (_selectedMethod == 'Bank Payment') {
      if (_bankNameController.text.trim().isEmpty) {
        _showError('Please enter your bank name.');
        return;
      }
      destination = '${_bankNameController.text.trim()} - $destination';
    }

    if (destination.isEmpty) {
      _showError('Please enter recipient account details.');
      return;
    }

    // For mobile wallet methods, validate digits
    if (_selectedMethod == 'bKash' || _selectedMethod == 'Nagad') {
      if (!RegExp(r'^\d+$').hasMatch(destination)) {
        _showError('Mobile number must contain digits only.');
        return;
      }
      if (destination.length < 11) {
        _showError('Please enter a valid 11-digit mobile number.');
        return;
      }
    }

    // Pop the request modal and open the 2-step review confirmation sheet
    Navigator.pop(context);
    PayoutConfirmationSheet.show(
      context,
      amount: amount,
      method: _selectedMethod,
      accountName: name,
      destination: destination,
      currency: wallet.currency,
    );
  }

  void _showError(String message) {
    AppToast.show(context, message: message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final presetAmounts = _getPresetAmounts(wallet.currency);
    final availableMethods = _getMethodsForCurrency(wallet.currency);
    final currentTypedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final isMobileMethod = _selectedMethod == 'bKash' || _selectedMethod == 'Nagad';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Request Payout',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () {
                        HapticService.lightImpact();
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Available Balance: ${wallet.currencySymbol}${wallet.balance.toStringAsFixed(2)} ${wallet.currencyCode}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Amount Section with editable custom TextField
                Text(
                  'PAYOUT AMOUNT (${wallet.currencyCode})',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Text(
                        wallet.currencySymbol,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: 'Enter custom amount',
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 12),

                // Quick Preset Chips
                Row(
                  children: presetAmounts.map((amount) {
                    final isSelected = currentTypedAmount == amount;

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: InkWell(
                          onTap: () {
                            HapticService.selectionClick();
                            setState(() {
                              _amountController.text = amount.toInt().toString();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.borderSubtle,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${wallet.currencySymbol}${amount.toInt()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.ctaText
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),

                // Payment Method Selector
                Text(
                  'PAYMENT METHOD',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableMethods.contains(_selectedMethod)
                          ? _selectedMethod
                          : availableMethods.first,
                      isExpanded: true,
                      dropdownColor: AppColors.surfaceCard,
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                      items: availableMethods.map((method) {
                        IconData methodIcon = Icons.payment;
                        if (method.contains('USDT') || method.contains('Binance')) {
                          methodIcon = Icons.currency_bitcoin;
                        } else if (method == 'bKash' || method == 'Nagad') {
                          methodIcon = Icons.phone_android;
                        } else if (method == 'Bank Payment') {
                          methodIcon = Icons.account_balance;
                        }

                        return DropdownMenuItem<String>(
                          value: method,
                          child: Row(
                            children: [
                              Icon(
                                methodIcon,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                method,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          HapticService.selectionClick();
                          setState(() => _selectedMethod = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Account Holder Name Field (Letters and spaces only)
                Text(
                  'ACCOUNT HOLDER NAME',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  style: const TextStyle(color: AppColors.primary),
                  decoration: const InputDecoration(
                    hintText: 'Enter full name (letters only)',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Bank Name (only if Bank Payment is selected)
                if (_selectedMethod == 'Bank Payment') ...[
                  Text(
                    'BANK NAME',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bankNameController,
                    style: const TextStyle(color: AppColors.primary),
                    decoration: const InputDecoration(
                      hintText: 'e.g. City Bank, BRAC Bank, Dutch Bangla',
                      prefixIcon: Icon(Icons.account_balance, color: AppColors.textMuted, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Number / Wallet Address / Account field
                Text(
                  _selectedMethod.contains('USDT (TRC20)')
                      ? 'USDT TRC20 WALLET ADDRESS'
                      : (_selectedMethod.contains('USDT (BEP20)')
                          ? 'USDT BEP20 (BSC) WALLET ADDRESS'
                          : (_selectedMethod.contains('Binance Pay')
                              ? 'BINANCE PAY ID / EMAIL / UID'
                              : (_selectedMethod == 'bKash'
                                  ? 'BKASH MOBILE NUMBER'
                                  : (_selectedMethod == 'Nagad'
                                      ? 'NAGAD MOBILE NUMBER'
                                      : (_selectedMethod == 'PayPal'
                                          ? 'PAYPAL EMAIL ADDRESS'
                                          : 'BANK ACCOUNT NUMBER / IBAN'))))),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _destinationController,
                  keyboardType: isMobileMethod
                      ? TextInputType.number
                      : (_selectedMethod == 'PayPal' || _selectedMethod.contains('Binance')
                          ? TextInputType.emailAddress
                          : TextInputType.text),
                  inputFormatters: isMobileMethod
                      ? [FilteringTextInputFormatter.digitsOnly]
                      : null,
                  style: const TextStyle(color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: _selectedMethod.contains('TRC20')
                        ? 'T... (TRC20 address)'
                        : (_selectedMethod.contains('BEP20')
                            ? '0x... (BEP20 address)'
                            : (_selectedMethod.contains('Binance')
                                ? 'Binance Pay ID / UID or email'
                                : (_selectedMethod == 'bKash' || _selectedMethod == 'Nagad'
                                    ? '01XXXXXXXXX (Digits only)'
                                    : (_selectedMethod == 'PayPal'
                                        ? 'name@example.com'
                                        : 'Enter bank account number')))),
                    prefixIcon: Icon(
                      _selectedMethod.contains('USDT')
                          ? Icons.account_balance_wallet_outlined
                          : (_selectedMethod == 'PayPal'
                              ? Icons.mail_outline
                              : (_selectedMethod.contains('Binance')
                                  ? Icons.qr_code_scanner
                                  : Icons.phone_android)),
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Process CTA Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _handleProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.ctaText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_forward_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Process',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
