import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/customer_refund_model.dart';

class CustomerRefundRepository {
  final DioClient _dioClient = DioClient();

  /// POST /refunds
  Future<CustomerRefundModel> requestRefund({
    required String ticketId,
    required String reason,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/refunds',
        data: {'ticketId': ticketId, 'reason': reason},
      );
      final data = response.data['data'];
      return CustomerRefundModel.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to submit refund request'),
      );
    }
  }

  /// GET /refunds/my-refunds
  Future<List<CustomerRefundModel>> getMyRefunds() async {
    try {
      final response = await _dioClient.dio.get('/refunds/my-refunds');
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => CustomerRefundModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to load refund requests'),
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
