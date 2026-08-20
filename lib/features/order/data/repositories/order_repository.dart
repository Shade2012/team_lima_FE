import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class OrderSeatRequest {
  final String categoryId;
  final String? seatId;
  final int quantity;

  OrderSeatRequest({required this.categoryId, this.seatId, this.quantity = 1});

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      if (seatId != null && seatId!.isNotEmpty) 'seatId': seatId,
      'quantity': quantity,
    };
  }
}

class CreateOrderResponse {
  final String id;
  final String eventId;
  final String userId;
  final double totalPrice;
  final String status;
  final String? providerTrxId;
  final String? snapToken;
  final String? snapRedirectUrl;

  CreateOrderResponse({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.totalPrice,
    required this.status,
    this.providerTrxId,
    this.snapToken,
    this.snapRedirectUrl,
  });

  factory CreateOrderResponse.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;

    final id = json['id']?.toString() ?? json['orderId']?.toString() ?? '';

    final totalPrice = json['totalAmount'] is num
        ? (json['totalAmount'] as num).toDouble()
        : json['totalPrice'] is num
        ? (json['totalPrice'] as num).toDouble()
        : double.tryParse(
                json['totalAmount']?.toString() ??
                    json['totalPrice']?.toString() ??
                    '',
              ) ??
              0.0;

    final providerTrxId =
        json['providerTrxId']?.toString() ??
        payment?['providerTrxId']?.toString();

    final snapToken =
        json['snapToken']?.toString() ?? payment?['snapToken']?.toString();

    final snapRedirectUrl =
        json['checkoutUrl']?.toString() ??
        json['snapRedirectUrl']?.toString() ??
        payment?['snapRedirectUrl']?.toString();

    return CreateOrderResponse(
      id: id,
      eventId: json['eventId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      totalPrice: totalPrice,
      status: json['status']?.toString() ?? 'HELD',
      providerTrxId: providerTrxId,
      snapToken: snapToken,
      snapRedirectUrl: snapRedirectUrl,
    );
  }
}

class OrderRepository {
  final DioClient _dioClient = DioClient();

  /// POST /orders/event/:eventId
  Future<CreateOrderResponse> createOrder({
    required String eventId,
    required List<OrderSeatRequest> seats,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/orders/event/$eventId',
        data: {'seats': seats.map((s) => s.toJson()).toList()},
      );
      final data = response.data['data'];
      return CreateOrderResponse.fromJson(data);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to create order'),
      );
    }
  }

  /// POST /mock-pg/simulate-payment
  Future<bool> simulatePayment({
    required String providerTrxId,
    required String
    paymentMethod, // VIRTUAL_ACCOUNT, GOPAY, SHOPPE_PAY, OVO, VELOCE_PAY
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/mock-pg/simulate-payment',
        data: {'providerTrxId': providerTrxId, 'paymentMethod': paymentMethod},
      );
      return response.data['data'] == true;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to complete payment'),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) return message.map((m) => m.toString()).join('\n');
      }
    }
    return e.message ?? fallback;
  }
}
