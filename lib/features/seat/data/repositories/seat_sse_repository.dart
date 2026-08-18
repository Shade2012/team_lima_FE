import 'dart:async';
import 'dart:convert';
import 'package:team_five_fe/core/network/sse_client.dart';
import 'package:team_five_fe/core/network/dio_client.dart';
import 'package:team_five_fe/core/constants/api_constants.dart';
import 'package:team_five_fe/features/seat/data/models/seat_model.dart';

class SeatUpdateEvent {
  final String categoryId;
  final List<Seat> seats;
  final String action;

  SeatUpdateEvent({
    required this.categoryId,
    required this.seats,
    required this.action,
  });

  factory SeatUpdateEvent.fromJson(Map<String, dynamic> json) {
    return SeatUpdateEvent(
      categoryId: json['categoryId'] ?? '',
      seats: (json['seats'] as List? ?? [])
          .map((s) => Seat.fromJson(s))
          .toList(),
      action: json['action'] ?? 'update',
    );
  }
}

class SeatSseRepository {
  final SseClient _client = SseClient();

  Stream<SeatUpdateEvent> watchSeats(String eventId) async* {
    final dioClient = DioClient();
    final token = dioClient.dio.options.headers['Authorization'];

    final url = '${ApiConstants.baseUrl}${ApiConstants.sseSeats(eventId)}';
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (token != null) 'Authorization': token.toString(),
    };

    await for (final event in _client.connect(url, headers: headers)) {
      if (event.data != null) {
        try {
          final json = jsonDecode(event.data!);
          yield SeatUpdateEvent.fromJson(json);
        } catch (_) {}
      }
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
