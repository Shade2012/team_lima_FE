import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import 'ticket_detail_page.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  final String eventName;
  final String eventCategory;
  final double price;
  final String location;

  const CheckoutPage({
    super.key,
    this.eventName = 'Neon Jungle Festival',
    this.eventCategory = 'LIVE EVENT',
    this.price = 150.0,
    this.location = 'Main Stage, Sector 4',
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _promoController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardHolderController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);
    final checkoutNotifier = ref.read(checkoutProvider.notifier);
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
                    _buildPaymentMethods(checkoutState, checkoutNotifier),

                    const SizedBox(height: 24),
                    // Billing Details Section
                    Text(
                      'Billing Details',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBillingDetails(checkoutState, checkoutNotifier),

                    const SizedBox(height: 24),
                    // Order Summary Section
                    _buildOrderSummary(
                      context,
                      checkoutState,
                      checkoutNotifier,
                      attendeeName,
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

  // ==================== Payment Methods Section ====================

  Widget _buildPaymentMethods(CheckoutState state, CheckoutNotifier notifier) {
    return Column(
      children: [
        // 1. Credit or Debit Card Option Box
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: state.paymentMethod == 'card'
                  ? AppColors.primary
                  : const Color(0xFFE5E5EA),
              width: state.paymentMethod == 'card' ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              // Header Radio Tile
              InkWell(
                onTap: () => notifier.setPaymentMethod('card'),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: 'card',
                        groupValue: state.paymentMethod,
                        activeColor: AppColors.primary,
                        onChanged: (val) => notifier.setPaymentMethod(val!),
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
                      // Card Brands Badges
                      _buildBrandBadge('VISA'),
                      const SizedBox(width: 4),
                      _buildBrandBadge('MC'),
                    ],
                  ),
                ),
              ),
              // Expanded Form Inputs (when card is selected)
              if (state.paymentMethod == 'card')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 1, color: Color(0xFFF0F0F5)),
                      const SizedBox(height: 12),
                      // Card Number Label & Field
                      Text(
                        'CARD NUMBER',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        style: AppTextStyles.bodyMedium,
                        decoration: _buildInputDecoration(
                          hintText: '0000 0000 0000 0000',
                          suffixIcon: Icons.credit_card_outlined,
                        ),
                        onChanged: (val) => notifier.setCardNumber(val),
                      ),
                      const SizedBox(height: 12),

                      // Expiry & CVC Row
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EXPIRY DATE',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _expiryController,
                                  keyboardType: TextInputType.datetime,
                                  style: AppTextStyles.bodyMedium,
                                  decoration: _buildInputDecoration(
                                    hintText: 'MM/YY',
                                  ),
                                  onChanged: (val) =>
                                      notifier.setExpiryDate(val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CVC',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _cvcController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  style: AppTextStyles.bodyMedium,
                                  decoration: _buildInputDecoration(
                                    hintText: '123',
                                    suffixIcon: Icons.info_outline,
                                  ),
                                  onChanged: (val) => notifier.setCvc(val),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cardholder Name
                      Text(
                        'CARDHOLDER NAME',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _cardHolderController,
                        style: AppTextStyles.bodyMedium,
                        decoration: _buildInputDecoration(
                          hintText: 'Name on card',
                        ),
                        onChanged: (val) => notifier.setCardHolderName(val),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Digital Wallet Option Box
        _buildPaymentOptionBox(
          title: 'Digital Wallet',
          value: 'wallet',
          groupValue: state.paymentMethod,
          icon: Icons.account_balance_wallet_outlined,
          onSelect: () => notifier.setPaymentMethod('wallet'),
        ),
        const SizedBox(height: 10),

        // 3. Bank Transfer Option Box
        _buildPaymentOptionBox(
          title: 'Bank Transfer',
          value: 'bank',
          groupValue: state.paymentMethod,
          icon: Icons.account_balance_outlined,
          onSelect: () => notifier.setPaymentMethod('bank'),
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
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: AppColors.primary,
              onChanged: (_) => onSelect(),
            ),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.black54,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
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

  // ==================== Billing Details ====================

  Widget _buildBillingDetails(CheckoutState state, CheckoutNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: state.sameAsProfileAddress,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) => notifier.toggleSameAsProfileAddress(val),
          ),
          Expanded(
            child: Text(
              'Same as account profile address',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== Order Summary Section ====================

  Widget _buildOrderSummary(
    BuildContext context,
    CheckoutState state,
    CheckoutNotifier notifier,
    String attendeeName,
  ) {
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
                // Thumbnail Box
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
                        widget.eventCategory,
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
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Oct 24, 2024',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
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
            '1x VIP Admission',
            '\$${widget.price.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryLine(
            'Service Fee',
            '\$${state.serviceFee.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
          _buildSummaryLine(
            'Taxes & Processing',
            '\$${state.taxesAndProcessing.toStringAsFixed(2)}',
          ),
          if (state.isPromoApplied) ...[
            const SizedBox(height: 8),
            _buildSummaryLine(
              'Promo Discount (VELOCE10)',
              '-\$${state.discount.toStringAsFixed(2)}',
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 16),

          // Promo Code Input Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  color: Colors.black38,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(
                      hintText: 'Promo Code',
                      hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => notifier.setPromoCode(val),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final applied = notifier.applyPromoCode();
                    if (applied) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promo code applied successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'APPLY',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'USD ',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    '\$${state.total.toStringAsFixed(2)}',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
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
                        eventName: widget.eventName,
                        attendeeName: attendeeName,
                      );
                      if (context.mounted && newTicket != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Payment completed successfully!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TicketDetailPage(ticket: newTicket),
                          ),
                        );
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
          // Subtext
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
