import 'package:dio/dio.dart';
import '../models/bulk_seats_request.dart';
import '../models/seat_model.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class BulkSeatsResponse {
  final int seatsCreated;
  final int totalQuota;
  final String prefix;
  final String firstSeatCode;
  final String lastSeatCode;

  BulkSeatsResponse({
    required this.seatsCreated,
    required this.totalQuota,
    required this.prefix,
    required this.firstSeatCode,
    required this.lastSeatCode,
  });

  factory BulkSeatsResponse.fromJson(Map<String, dynamic> json) {
    return BulkSeatsResponse(
      seatsCreated: json['seatsCreated'] ?? 0,
      totalQuota: json['totalQuota'] ?? 0,
      prefix: json['prefix']?.toString() ?? '',
      firstSeatCode: json['firstSeatCode']?.toString() ?? '',
      lastSeatCode: json['lastSeatCode']?.toString() ?? '',
    );
  }
}

class SeatRepository {
  final DioClient _dioClient = DioClient();

  /// POST /seats/bulk
  Future<BulkSeatsResponse> bulkGenerateSeats(BulkSeatsRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.bulkSeats,
        data: request.toJson(),
      );
      return BulkSeatsResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to generate seats'),
      );
    }
  }

  /// GET /seats/category/:categoryId
  Future<int> getSeatsCountByCategory(String categoryId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.seatsByCategory(categoryId),
      );
      final data = response.data['data'] as List;
      return data.length;
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch seats'),
      );
    }
  }

  /// GET /seats/category/:categoryId (returns full seat list)
  Future<List<Seat>> getSeatsByCategory(String categoryId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.seatsByCategory(categoryId),
      );
      final data = response.data['data'] as List;
      return data.map((e) => Seat.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch seats'),
      );
    }
  }

  /// DELETE /seats/category/:categoryId
  Future<void> deleteSeatsByCategory(String categoryId) async {
    try {
      await _dioClient.dio.delete(
        ApiConstants.deleteSeatsByCategory(categoryId),
      );
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to delete seats'),
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
