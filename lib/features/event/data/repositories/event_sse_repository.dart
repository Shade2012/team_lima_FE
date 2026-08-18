import 'dart:async';
import 'dart:convert';
import 'package:team_five_fe/core/network/sse_client.dart';
import 'package:team_five_fe/core/network/dio_client.dart';
import 'package:team_five_fe/core/constants/api_constants.dart';

class DashboardUpdateEvent {
  final int totalTicketsSold;
  final int totalRevenue;
  final int scannedCount;
  final Map<String, dynamic>? categoryStats;

  DashboardUpdateEvent({
    required this.totalTicketsSold,
    required this.totalRevenue,
    required this.scannedCount,
    this.categoryStats,
  });

  factory DashboardUpdateEvent.fromJson(Map<String, dynamic> json) {
    return DashboardUpdateEvent(
      totalTicketsSold: json['totalTicketsSold'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      scannedCount: json['scannedCount'] ?? 0,
      categoryStats: json['categoryStats'],
    );
  }
}

class EventSseRepository {
  final SseClient _client = SseClient();

  Stream<DashboardUpdateEvent> watchDashboard(String eventId) async* {
    final dioClient = DioClient();
    final token = dioClient.dio.options.headers['Authorization'];

    final url = '${ApiConstants.baseUrl}${ApiConstants.sseDashboard(eventId)}';
    final headers = <String, String>{
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      if (token != null) 'Authorization': token.toString(),
    };

    await for (final event in _client.connect(url, headers: headers)) {
      if (event.data != null) {
        try {
          final json = jsonDecode(event.data!);
          yield DashboardUpdateEvent.fromJson(json);
        } catch (_) {}
      }
    }
  }

  void disconnect() {
    _client.disconnect();
  }
}
