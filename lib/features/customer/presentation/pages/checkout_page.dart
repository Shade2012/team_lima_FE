import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../widgets/top_up_dialog.dart';
import 'ticket_detail_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final String? eventId;
  final String? categoryId;
  final String? seatId;
  final String? seatCode;
  final String eventName;
  final String eventCategory;
  final double price;
  final String location;
  final DateTime? eventDate;
  final String? eventTimeRange;
  final String? venueName;
  final String? venueAddress;
  final String? ticketType;

  const CheckoutPage({
    super.key,
    this.eventId,
    this.categoryId,
    this.seatId,
    this.seatCode,
    this.eventName = 'Event Ticket',
    this.eventCategory = 'General Admission',
    this.price = 150.0,
    this.location = 'Main Stage Pavilion',
    this.eventDate,
    this.eventTimeRange,
    this.venueName,
    this.venueAddress,
    this.ticketType,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardHolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).setAdmissionPrice(widget.price);
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount > 10000) {
      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      );
      return formatter.format(amount);
    }
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
    final walletState = ref.watch(customerWalletProvider);
    final walletNotifier = ref.read(customerWalletProvider.notifier);
    final authState = ref.watch(authProvider);

    final attendeeName = authState.currentUser?.username.isNotEmpty == true
        ? authState.currentUser!.username
        : 'Alex Chen';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            _buildAppBar(context),
            // Form Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Text(
                      'Secure Checkout',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete your purchase for the upcoming event.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Method Section
                    Text(
                      'Payment Method',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentMethods(
                      checkoutState,
                      checkoutNotifier,
                      walletState,
                      walletNotifier,
                    ),

                    const SizedBox(height: 24),
                    // Order Summary Section
                    _buildOrderSummary(
                      context,
                      checkoutState,
                      checkoutNotifier,
                      attendeeName,
                      walletState,
                      walletNotifier,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== Header Bar ====================

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.black),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          Flexible(
            child: Text(
              'VELOCE',
              style: AppTextStyles.title.copyWith(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing event details...')),
              );
            },
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.primary,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(
    CheckoutState state,
    CheckoutNotifier notifier,
    CustomerWalletState walletState,
    CustomerWalletNotifier walletNotifier,
  ) {
    final isWalletInsufficient =
        state.paymentMethod == 'E_WALLET' && walletState.balance < state.total;

    return Column(
      children: [
        // 1. E_WALLET (Veloce e-Wallet Option)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.paymentMethod == 'E_WALLET'
                  ? AppColors.primary
                  : const Color(0xFFE5E5EA),
              width: state.paymentMethod == 'E_WALLET' ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => notifier.setPaymentMethod('E_WALLET'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.paymentMethod == 'E_WALLET'
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            width: state.paymentMethod == 'E_WALLET' ? 6 : 2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Veloce Wallet (E-Wallet)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Balance: ${_formatCurrency(walletState.balance)}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isWalletInsufficient
                                    ? AppColors.danger
                                    : AppColors.grey,
                                fontWeight: isWalletInsufficient
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => TopUpDialog.show(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '+ Top Up',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (state.paymentMethod == 'E_WALLET' && isWalletInsufficient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Insufficient wallet balance. Tap Top Up to add funds.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.danger,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. CREDIT_CARD Option Box
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.paymentMethod == 'CREDIT_CARD'
                  ? AppColors.primary
                  : const Color(0xFFE5E5EA),
              width: state.paymentMethod == 'CREDIT_CARD' ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => notifier.setPaymentMethod('CREDIT_CARD'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.paymentMethod == 'CREDIT_CARD'
                                ? AppColors.primary
                                : Colors.grey.shade400,
                            width: state.paymentMethod == 'CREDIT_CARD' ? 6 : 2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.credit_card,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Credit or Debit Card',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      _buildBrandBadge('VISA'),
                      const SizedBox(width: 4),
                      _buildBrandBadge('MC'),
                    ],
                  ),
                ),
              ),
              if (state.paymentMethod == 'CREDIT_CARD')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFF0F0F5)),
                      const SizedBox(height: 12),
                      Text(
                        'CARD NUMBER',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        decoration: _buildInputDecoration(
                          hintText: '4000 0000 0000 0000',
                          suffixIcon: Icons.credit_card_outlined,
                        ),
                        onChanged: (val) => notifier.setCardNumber(val),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3. BANK_TRANSFER Option Box
        _buildPaymentOptionBox(
          title: 'Bank Transfer (Virtual Account)',
          value: 'BANK_TRANSFER',
          groupValue: state.paymentMethod,
          icon: Icons.account_balance_outlined,
          onSelect: () => notifier.setPaymentMethod('BANK_TRANSFER'),
        ),
        const SizedBox(height: 10),

        // 4. QRIS Option Box
        _buildPaymentOptionBox(
          title: 'QRIS Instant Scan',
          value: 'QRIS',
          groupValue: state.paymentMethod,
          icon: Icons.qr_code_scanner_outlined,
          onSelect: () => notifier.setPaymentMethod('QRIS'),
        ),
      ],
    );
  }

  Widget _buildBrandBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFF4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildPaymentOptionBox({
    required String title,
    required String value,
    required String groupValue,
    required IconData icon,
    required VoidCallback onSelect,
  }) {
    final isSelected = value == groupValue;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE5E5EA),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    IconData? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.black38),
      filled: true,
      fillColor: const Color(0xFFF9FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon != null
          ? Icon(suffixIcon, color: Colors.black26, size: 18)
          : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  // ==================== Order Summary Section ====================

  Widget _buildOrderSummary(
    BuildContext context,
    CheckoutState state,
    CheckoutNotifier notifier,
    String attendeeName,
    CustomerWalletState walletState,
    CustomerWalletNotifier walletNotifier,
  ) {
    final seatLabel = widget.seatCode != null
        ? ' (Seat ${widget.seatCode})'
        : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 14),

          // Event Card Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A004E), Color(0xFFAF06FF)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.eventCategory}$seatLabel',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.eventName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.location,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F5)),
          const SizedBox(height: 14),

          // Price Breakdown
          _buildSummaryLine(
            '1x Ticket Admission',
            _formatCurrency(state.admissionPrice),
          ),
          const SizedBox(height: 8),
          _buildSummaryLine('Service Fee', _formatCurrency(state.serviceFee)),
          const SizedBox(height: 8),
          _buildSummaryLine(
            'Taxes & Processing',
            _formatCurrency(state.taxesAndProcessing),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F5)),
          const SizedBox(height: 16),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Text(
                _formatCurrency(state.total),
                style: AppTextStyles.title.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Complete Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isProcessing
                  ? null
                  : () async {
                      final newTicket = await notifier.completePayment(
                        eventId: widget.eventId,
                        categoryId: widget.categoryId,
                        seatId: widget.seatId,
                        seatCode: widget.seatCode,
                        eventName: widget.eventName,
                        categoryName: widget.eventCategory,
                        attendeeName: attendeeName,
                        eventDate: widget.eventDate,
                        eventTimeRange: widget.eventTimeRange,
                        venueName: widget.venueName ?? widget.location,
                        venueAddress: widget.venueAddress,
                        ticketType: widget.ticketType,
                      );
                      if (context.mounted) {
                        if (newTicket != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment completed successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TicketDetailPage(
                                ticket: newTicket,
                                isFromCheckout: true,
                              ),
                            ),
                          );
                        } else if (state.error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error!),
                              backgroundColor: AppColors.danger,
                              action: state.paymentMethod == 'E_WALLET'
                                  ? SnackBarAction(
                                      label: 'TOP UP',
                                      textColor: Colors.white,
                                      onPressed: () =>
                                          TopUpDialog.show(context),
                                    )
                                  : null,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: state.isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Complete Payment',
                          style: AppTextStyles.button.copyWith(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Transactions are 100% secure and encrypted.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.black45,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.black54,
            fontSize: 13,
          ),
        ),
        Text(
          amount,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isDiscount ? AppColors.success : AppColors.black,
          ),
        ),
      ],
    );
  }
}
