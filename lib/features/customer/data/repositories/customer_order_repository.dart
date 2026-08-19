import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_order_model.dart';

class CustomerOrderRepository {
  final DioClient _dioClient = DioClient();

  /// GET /orders/customer
  Future<List<CustomerOrderModel>> getCustomerOrders() async {
    try {
      final response = await _dioClient.dio.get('/orders/customer');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => CustomerOrderModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load customer orders'),
      );
    }
  }

  /// GET /orders/customer/:id
  Future<CustomerOrderModel> getOrderDetail(String orderId) async {
    try {
      final response = await _dioClient.dio.get('/orders/customer/$orderId');
      final data = response.data['data'];
      return CustomerOrderModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load order details'),
      );
    }
  }

  /// GET /orders/clear
  Future<bool> clearOrders() async {
    try {
      final response = await _dioClient.dio.get('/orders/clear');
      return response.data['data'] == true;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to clear orders'),
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
