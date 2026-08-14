import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../models/create_event_request.dart';
import '../models/update_event_request.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';

class EventRepository {
  final DioClient _dioClient = DioClient();

  /// GET /events (Public)
  Future<List<Event>> getAllEvents() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.events);
      final data = response.data['data'] as List;
      return data.map((e) => Event.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch public events'),
      );
    }
  }

  /// GET /events/organizer/me
  Future<List<Event>> getMyEvents() async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.myOrganizerEvents);
      final data = response.data['data'] as List;
      return data.map((e) => Event.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch events'),
      );
    }
  }

  /// GET /events/:id
  Future<Event> getEventDetail(String id) async {
    try {
      final response = await _dioClient.dio.get(ApiConstants.eventDetail(id));
      return Event.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to fetch event detail'),
      );
    }
  }

  /// POST /events
  Future<Event> createEvent(CreateEventRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiConstants.events,
        data: request.toJson(),
      );
      return Event.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to create event'),
      );
    }
  }

  /// PATCH /events/:id
  Future<Event> updateEvent(String id, UpdateEventRequest request) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiConstants.eventDetail(id),
        data: request.toJson(),
      );
      return Event.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to update event'),
      );
    }
  }

  /// DELETE /events/:id
  Future<void> deleteEvent(String id) async {
    try {
      await _dioClient.dio.delete(ApiConstants.eventDetail(id));
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, fallback: 'Failed to delete event'),
      );
    }
  }

  String _extractErrorMessage(DioException e, {required String fallback}) {
    if (e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String) {
          return message;
        } else if (message is List) {
          return message.map((m) => m.toString()).join('\n');
        }
      }
    }
    return e.message ?? fallback;
  }
}
