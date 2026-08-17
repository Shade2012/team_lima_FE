import 'package:dio/dio.dart';
import '../models/refund_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminRefundRepository {
  final DioClient _dioClient = DioClient();

  /// GET /refunds
  Future<List<RefundRequest>> getRefundRequests() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.refunds);
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data
            .map((e) => RefundRequest.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch refund requests'),
      );
    }
  }

  /// PATCH /refunds/:id/approve
  Future<void> approveRefund(String id) async {
    try {
      await _dioClient.dio.patch(ApiConstants.refundApprove(id));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to approve refund'),
      );
    }
  }

  /// PATCH /refunds/:id/reject
  Future<void> rejectRefund(String id, {required String reason}) async {
    try {
      await _dioClient.dio.patch(
        ApiConstants.refundReject(id),
        data: {'rejectReason': reason},
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to reject refund'),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) return message;
        if (message is List) {
          return message.map((m) => m.toString()).join('\n');
        }
      }
    }
    return e.message ?? fallback;
  }
}
