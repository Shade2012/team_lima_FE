import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_ticket_model.dart';
import '../../data/models/customer_order_model.dart';
import '../../data/models/customer_refund_model.dart';
import '../../data/repositories/customer_ticket_repository.dart';
import '../../data/repositories/customer_order_repository.dart';
import '../../data/repositories/customer_refund_repository.dart';
import '../../../event/data/models/event_model.dart';
import '../../../event/presentation/providers/event_provider.dart';
import '../../../order/data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

final customerTicketRepositoryProvider = Provider<CustomerTicketRepository>((
  ref,
) {
  return CustomerTicketRepository();
});

final customerOrderRepositoryProvider = Provider<CustomerOrderRepository>((
  ref,
) {
  return CustomerOrderRepository();
});

final customerRefundRepositoryProvider = Provider<CustomerRefundRepository>((
  ref,
) {
  return CustomerRefundRepository();
});

// ==================== Customer Wallet State ====================

class WalletTransaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final bool isTopUp;

  WalletTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.isTopUp,
  });
}

class CustomerWalletState {
  final double balance;
  final List<WalletTransaction> transactions;
  final bool isLoading;
  final String? error;

  CustomerWalletState({
    this.balance = 0.0,
    this.transactions = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerWalletState copyWith({
    double? balance,
    List<WalletTransaction>? transactions,
    bool? isLoading,
    String? error,
  }) {
    return CustomerWalletState(
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerWalletNotifier extends Notifier<CustomerWalletState> {
  @override
  CustomerWalletState build() {
    return CustomerWalletState();
  }

  void topUp(double amount) {
    if (amount <= 0) return;
    final newTx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Wallet Top Up',
      amount: amount,
      date: DateTime.now(),
      isTopUp: true,
    );
    state = state.copyWith(
      balance: state.balance + amount,
      transactions: [newTx, ...state.transactions],
    );
  }

  bool deduct(double amount, String description) {
    if (state.balance < amount) return false;
    final newTx = WalletTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      title: description,
      amount: amount,
      date: DateTime.now(),
      isTopUp: false,
    );
    state = state.copyWith(
      balance: state.balance - amount,
      transactions: [newTx, ...state.transactions],
    );
    return true;
  }
}

final customerWalletProvider =
    NotifierProvider<CustomerWalletNotifier, CustomerWalletState>(() {
      return CustomerWalletNotifier();
    });

// ==================== Customer Explore State ====================

class CustomerExploreState {
  final List<Event> events;
  final String selectedCategory;
  final String searchQuery;
  final Set<String> savedEventIds;
  final bool isLoading;
  final String? error;

  CustomerExploreState({
    this.events = const [],
    this.selectedCategory = 'All Events',
    this.searchQuery = '',
    this.savedEventIds = const {},
    this.isLoading = false,
    this.error,
  });

  CustomerExploreState copyWith({
    List<Event>? events,
    String? selectedCategory,
    String? searchQuery,
    Set<String>? savedEventIds,
    bool? isLoading,
    String? error,
  }) {
    return CustomerExploreState(
      events: events ?? this.events,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      savedEventIds: savedEventIds ?? this.savedEventIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Event> get filteredEvents {
    return events.where((event) {
      final matchesSearch =
          searchQuery.isEmpty ||
          event.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }
}

class CustomerExploreNotifier extends Notifier<CustomerExploreState> {
  @override
  CustomerExploreState build() {
    Future.microtask(() => loadPublicEvents());
    return CustomerExploreState();
  }

  Future<void> loadPublicEvents({bool forceRefresh = false}) async {
    if (!forceRefresh && (state.isLoading || state.events.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(eventRepositoryProvider);
      final events = await repository.getAllEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSaveEvent(String eventId) {
    final updated = Set<String>.from(state.savedEventIds);
    if (updated.contains(eventId)) {
      updated.remove(eventId);
    } else {
      updated.add(eventId);
    }
    state = state.copyWith(savedEventIds: updated);
  }
}

final customerExploreProvider =
    NotifierProvider<CustomerExploreNotifier, CustomerExploreState>(() {
      return CustomerExploreNotifier();
    });

// ==================== Customer Tickets State ====================

class CustomerTicketsState {
  final List<CustomerTicket> tickets;
  final bool isLoading;
  final String? error;

  CustomerTicketsState({
    this.tickets = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerTicketsState copyWith({
    List<CustomerTicket>? tickets,
    bool? isLoading,
    String? error,
  }) {
    return CustomerTicketsState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerTicketsNotifier extends Notifier<CustomerTicketsState> {
  @override
  CustomerTicketsState build() {
    Future.microtask(() => loadTickets());
    return CustomerTicketsState();
  }

  Future<void> loadTickets({bool forceRefresh = false}) async {
    if (!forceRefresh && (state.isLoading || state.tickets.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(customerTicketRepositoryProvider);
      final fetchedTickets = await repo.getMyTickets();
      state = state.copyWith(tickets: fetchedTickets, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void addTicket(CustomerTicket ticket) {
    state = state.copyWith(tickets: [ticket, ...state.tickets]);
  }

  void markTicketRefunded(String ticketId) {
    final updated = state.tickets.map((t) {
      if (t.id == ticketId) {
        return CustomerTicket(
          id: t.id,
          ticketCode: t.ticketCode,
          eventName: t.eventName,
          categoryName: t.categoryName,
          eventDate: t.eventDate,
          eventTimeRange: t.eventTimeRange,
          venueName: t.venueName,
          venueAddress: t.venueAddress,
          attendeeName: t.attendeeName,
          ticketType: t.ticketType,
          qrData: t.qrData,
          status: 'REFUNDED',
          imageUrl: t.imageUrl,
          price: t.price,
        );
      }
      return t;
    }).toList();
    state = state.copyWith(tickets: updated);
  }
}

final customerTicketsProvider =
    NotifierProvider<CustomerTicketsNotifier, CustomerTicketsState>(() {
      return CustomerTicketsNotifier();
    });

// ==================== Customer Orders State ====================

class CustomerOrdersState {
  final List<CustomerOrderModel> orders;
  final bool isLoading;
  final String? error;

  CustomerOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerOrdersState copyWith({
    List<CustomerOrderModel>? orders,
    bool? isLoading,
    String? error,
  }) {
    return CustomerOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CustomerOrdersNotifier extends Notifier<CustomerOrdersState> {
  @override
  CustomerOrdersState build() {
    Future.microtask(() => loadOrders());
    return CustomerOrdersState();
  }

  Future<void> loadOrders({bool forceRefresh = false}) async {
    if (!forceRefresh && (state.isLoading || state.orders.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(customerOrderRepositoryProvider);
      final orders = await repo.getCustomerOrders();
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

final customerOrdersProvider =
    NotifierProvider<CustomerOrdersNotifier, CustomerOrdersState>(() {
      return CustomerOrdersNotifier();
    });

// ==================== Customer Refunds State ====================

class CustomerRefundsState {
  final List<CustomerRefundModel> refunds;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  CustomerRefundsState({
    this.refunds = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  CustomerRefundsState copyWith({
    List<CustomerRefundModel>? refunds,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
  }) {
    return CustomerRefundsState(
      refunds: refunds ?? this.refunds,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class CustomerRefundsNotifier extends Notifier<CustomerRefundsState> {
  @override
  CustomerRefundsState build() {
    Future.microtask(() => loadRefunds());
    return CustomerRefundsState();
  }

  Future<void> loadRefunds({bool forceRefresh = false}) async {
    if (!forceRefresh && (state.isLoading || state.refunds.isNotEmpty)) {
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(customerRefundRepositoryProvider);
      final list = await repo.getMyRefunds();
      state = state.copyWith(refunds: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> submitRefund({
    required String ticketId,
    required String reason,
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final repo = ref.read(customerRefundRepositoryProvider);
      final newRefund = await repo.requestRefund(
        ticketId: ticketId,
        reason: reason,
      );
      state = state.copyWith(
        refunds: [newRefund, ...state.refunds],
        isSubmitting: false,
      );
      // Mark ticket refunded in CustomerTicketsNotifier
      ref.read(customerTicketsProvider.notifier).markTicketRefunded(ticketId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final customerRefundsProvider =
    NotifierProvider<CustomerRefundsNotifier, CustomerRefundsState>(() {
      return CustomerRefundsNotifier();
    });

// ==================== Checkout State ====================

class CheckoutState {
  final String paymentMethod;
  final String cardNumber;
  final String expiryDate;
  final String cvc;
  final String cardHolderName;
  final bool sameAsProfileAddress;
  final String promoCode;
  final bool isPromoApplied;
  final double admissionPrice;
  final double serviceFee;
  final double taxesAndProcessing;
  final double discount;
  final bool isProcessing;
  final String? error;

  CheckoutState({
    this.paymentMethod = 'VELOCE_PAY',
    this.cardNumber = '',
    this.expiryDate = '',
    this.cvc = '',
    this.cardHolderName = '',
    this.sameAsProfileAddress = true,
    this.promoCode = '',
    this.isPromoApplied = false,
    this.admissionPrice = 750000.0,
    this.serviceFee = 5000.0,
    this.taxesAndProcessing = 2500.0,
    this.discount = 0.0,
    this.isProcessing = false,
    this.error,
  });

  double get total =>
      admissionPrice + serviceFee + taxesAndProcessing - discount;

  CheckoutState copyWith({
    String? paymentMethod,
    String? cardNumber,
    String? expiryDate,
    String? cvc,
    String? cardHolderName,
    bool? sameAsProfileAddress,
    String? promoCode,
    bool? isPromoApplied,
    double? admissionPrice,
    double? serviceFee,
    double? taxesAndProcessing,
    double? discount,
    bool? isProcessing,
    String? error,
  }) {
    return CheckoutState(
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cvc: cvc ?? this.cvc,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      sameAsProfileAddress: sameAsProfileAddress ?? this.sameAsProfileAddress,
      promoCode: promoCode ?? this.promoCode,
      isPromoApplied: isPromoApplied ?? this.isPromoApplied,
      admissionPrice: admissionPrice ?? this.admissionPrice,
      serviceFee: serviceFee ?? this.serviceFee,
      taxesAndProcessing: taxesAndProcessing ?? this.taxesAndProcessing,
      discount: discount ?? this.discount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  @override
  CheckoutState build() {
    return CheckoutState();
  }

  void setAdmissionPrice(double price) {
    state = state.copyWith(admissionPrice: price);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setCardNumber(String value) {
    state = state.copyWith(cardNumber: value);
  }

  void setExpiryDate(String value) {
    state = state.copyWith(expiryDate: value);
  }

  void setCvc(String value) {
    state = state.copyWith(cvc: value);
  }

  void setCardHolderName(String value) {
    state = state.copyWith(cardHolderName: value);
  }

  void toggleSameAsProfileAddress(bool? value) {
    state = state.copyWith(sameAsProfileAddress: value ?? true);
  }

  void setPromoCode(String code) {
    state = state.copyWith(promoCode: code);
  }

  bool applyPromoCode() {
    if (state.promoCode.trim().toUpperCase() == 'VELOCE10' ||
        state.promoCode.trim().toUpperCase() == 'DISCOUNT') {
      state = state.copyWith(isPromoApplied: true, discount: 15.0, error: null);
      return true;
    } else {
      state = state.copyWith(error: 'Invalid promo code');
      return false;
    }
  }

  Future<CustomerTicket?> completePayment({
    String? eventId,
    String? categoryId,
    String? seatId,
    String? seatCode,
    required String eventName,
    String? categoryName,
    required String attendeeName,
    DateTime? eventDate,
    String? eventTimeRange,
    String? venueName,
    String? venueAddress,
    String? ticketType,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);

    try {
      final totalAmount = state.total;

      if (state.paymentMethod == 'VELOCE_PAY') {
        final walletBalance = ref.read(customerWalletProvider).balance;
        if (walletBalance < totalAmount) {
          state = state.copyWith(
            isProcessing: false,
            error: 'Insufficient Wallet Balance. Please top up your wallet.',
          );
          return null;
        }
      }

      final targetEventId = (eventId != null && eventId.isNotEmpty)
          ? eventId
          : '019146a0-7d1e-7abc-9a12-abcdef123456';
      final targetCategoryId = (categoryId != null && categoryId.isNotEmpty)
          ? categoryId
          : '019146a0-7d1e-7abc-9a12-category0001';

      final orderRepo = ref.read(orderRepositoryProvider);
      CreateOrderResponse? orderResponse;
      try {
        orderResponse = await orderRepo.createOrder(
          eventId: targetEventId,
          seats: [
            OrderSeatRequest(
              categoryId: targetCategoryId,
              seatId: seatId,
              quantity: 1,
            ),
          ],
        );
      } catch (_) {
        orderResponse = CreateOrderResponse(
          id: '019146a0-order-${DateTime.now().millisecondsSinceEpoch}',
          eventId: targetEventId,
          userId: 'user_001',
          totalPrice: totalAmount,
          status: 'HELD',
          providerTrxId: 'TRX-MOCK-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      final trxId =
          orderResponse.providerTrxId ??
          'TRX-MOCK-${DateTime.now().millisecondsSinceEpoch}';
      try {
        await orderRepo.simulatePayment(
          providerTrxId: trxId,
          paymentMethod: state.paymentMethod,
        );
      } catch (_) {}

      if (state.paymentMethod == 'VELOCE_PAY') {
        ref
            .read(customerWalletProvider.notifier)
            .deduct(totalAmount, 'Ticket Purchase: $eventName');
      }

      // Try fetching the real tickets from backend after successful payment
      try {
        final ticketRepo = ref.read(customerTicketRepositoryProvider);
        final realTickets = await ticketRepo.getMyTickets();
        if (realTickets.isNotEmpty) {
          final fetchedTicket = realTickets.first;
          ref
              .read(customerTicketsProvider.notifier)
              .loadTickets(forceRefresh: true);
          ref.read(customerOrdersProvider.notifier).loadOrders();
          state = state.copyWith(isProcessing: false, error: null);
          return fetchedTicket;
        }
      } catch (_) {}

      final displayCategory = categoryName ?? 'General Admission';
      final displaySeat = (seatCode != null && seatCode.isNotEmpty)
          ? seatCode
          : '#TKN-${(1000 + DateTime.now().millisecond % 9000)}';

      final fallbackTicketId =
          '019146a0-${DateTime.now().millisecondsSinceEpoch}';

      final newTicket = CustomerTicket(
        id: fallbackTicketId,
        ticketCode: displaySeat,
        eventName: eventName,
        categoryName: displayCategory,
        eventDate: eventDate ?? DateTime.now().add(const Duration(days: 7)),
        eventTimeRange: eventTimeRange ?? '07:00 PM - 11:00 PM',
        venueName: venueName ?? 'Main Stage Pavilion',
        venueAddress: venueAddress ?? 'Grand Exhibition Center',
        attendeeName: attendeeName.isNotEmpty ? attendeeName : 'Customer',
        ticketType: ticketType ?? 'E-Ticket',
        qrData:
            'DIGITAL TICKET | VELOCE\n$eventName\n$displayCategory\n$displaySeat\nID: $fallbackTicketId',
        status: 'UPCOMING',
        price: totalAmount,
      );

      ref.read(customerTicketsProvider.notifier).addTicket(newTicket);
      ref.read(customerOrdersProvider.notifier).loadOrders();
      state = state.copyWith(isProcessing: false, error: null);
      return newTicket;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }
}

final checkoutProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(() {
  return CheckoutNotifier();
});
