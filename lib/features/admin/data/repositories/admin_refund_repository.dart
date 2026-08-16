import 'package:dio/dio.dart';
import '../models/refund_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class AdminRefundRepository {
  final DioClient _dioClient = DioClient();

  /// GET /admin/refunds?status=PENDING
  Future<List<RefundRequest>> getRefundRequests({String? status}) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.adminRefunds,
        queryParameters: status != null ? {'status': status} : null,
      );
      final data = response.data['data'];
      if (data == null) return [];
      if (data is List) {
        return data.map((e) => RefundRequest.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch refund requests'),
      );
    }
  }

  /// GET /admin/refunds/:id
  Future<RefundRequest> getRefundDetail(String id) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.adminRefundDetail(id),
      );
      return RefundRequest.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch refund detail'),
      );
    }
  }

  /// POST /admin/refunds/:id/approve
  Future<void> approveRefund(String id, {String? notes}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.adminRefundApprove(id),
        data: notes != null ? {'notes': notes} : null,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to approve refund'),
      );
    }
  }

  /// POST /admin/refunds/:id/reject
  Future<void> rejectRefund(String id, {String? reason}) async {
    try {
      await _dioClient.dio.post(
        ApiConstants.adminRefundReject(id),
        data: reason != null ? {'reason': reason} : null,
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to reject refund'),
      );
    }
  }

  /// GET /admin/refunds/stats
  Future<RefundStats> getRefundStats() async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.adminRefundStats,
      );
      return RefundStats.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch refund stats'),
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
