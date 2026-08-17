import 'package:dio/dio.dart';
import '../models/ticket_category_model.dart';
import '../models/create_ticket_category_request.dart';
import '../models/update_ticket_category_request.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class TicketCategoryRepository {
  final DioClient _dioClient = DioClient();

  /// GET /ticket-categories/event/:eventId
  Future<List<TicketCategory>> getCategoriesByEvent(String eventId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiConstants.categoriesByEvent(eventId),
      );
      final data = response.data['data'] as List;
      return data.map((e) => TicketCategory.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch categories'),
      );
    }
  }

  /// POST /ticket-categories
  Future<TicketCategory> createCategory(
    CreateTicketCategoryRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.ticketCategories,
        data: request.toJson(),
      );
      return TicketCategory.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to create category'),
      );
    }
  }

  /// DELETE /ticket-categories/:id
  Future<void> deleteCategory(String id) async {
    try {
      await _dioClient.dio.delete(ApiConstants.categoryDetail(id));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to delete category'),
      );
    }
  }

  /// PATCH /ticket-categories/:id
  Future<TicketCategory> updateCategory(
    String id,
    UpdateTicketCategoryRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConstants.categoryDetail(id),
        data: request.toJson(),
      );
      return TicketCategory.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to update category'),
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
