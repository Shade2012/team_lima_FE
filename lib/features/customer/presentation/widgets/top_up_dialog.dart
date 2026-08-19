import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/customer_provider.dart';

/// Reusable Top Up Dialog for Veloce E-Wallet.
///
/// Designed for easy refactoring:
/// When backend Top-Up API endpoint becomes available, simply pass [onTopUp] callback
/// or update [CustomerWalletNotifier.topUp] to invoke backend repository.
class TopUpDialog extends ConsumerStatefulWidget {
  /// Optional async callback to connect with backend API when ready.
  /// Example: `onTopUp: (amount) async => await walletRepository.topUp(amount)`
  final Future<bool> Function(double amount)? onTopUp;

  const TopUpDialog({super.key, this.onTopUp});

  static Future<void> show(
    BuildContext context, {
    Future<bool> Function(double amount)? onTopUp,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TopUpDialog(onTopUp: onTopUp),
    );
  }

  @override
  ConsumerState<TopUpDialog> createState() => _TopUpDialogState();
}

class _TopUpDialogState extends ConsumerState<TopUpDialog> {
  final _amountController = TextEditingController(text: '100000');
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  Future<void> _handleTopUp() async {
    final rawText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(rawText) ?? 0.0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid top up amount'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      bool success = true;
      if (widget.onTopUp != null) {
        // Backend API hook
        success = await widget.onTopUp!(amount);
      } else {
        // Invoke wallet notifier topUp API
        success = await ref.read(customerWalletProvider.notifier).topUp(amount);
      }

      if (mounted) {
        Navigator.pop(context);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Top up of ${_formatCurrency(amount)} successful!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Top up failed: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Top Up Veloce Wallet',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter top-up amount:',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.title.copyWith(fontSize: 18),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: AppTextStyles.title.copyWith(
                  fontSize: 18,
                  color: AppColors.primary,
                ),
                hintText: '50.000',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Quick Nominal:',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [50000, 100000, 250000, 500000].map((amt) {
                return ActionChip(
                  label: Text(
                    'Rp ${amt ~/ 1000}k',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: const Color(0xFFF4F5F9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  onPressed: () {
                    setState(() {
                      _amountController.text = amt.toString();
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.black54),
          ),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleTopUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Top Up Now'),
        ),
      ],
    );
  }
}
