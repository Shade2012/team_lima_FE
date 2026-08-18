import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SseEvent {
  final String? event;
  final String? data;
  final String? id;
  final int? retry;

  SseEvent({this.event, this.data, this.id, this.retry});
}

class SseClient {
  HttpClient? _client;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Stream<SseEvent> connect(String url, {Map<String, String>? headers}) async* {
    final uri = Uri.parse(url);
    _client = HttpClient();
    final request = await _client!.getUrl(uri);

    headers?.forEach((key, value) {
      request.headers.set(key, value);
    });

    request.headers.set('Accept', 'text/event-stream');
    request.headers.set('Cache-Control', 'no-cache');

    final response = await request.close();
    _isConnected = true;

    String eventType = 'message';
    String eventData = '';
    String? eventId;
    int? retry;

    try {
      await for (final chunk in response.transform(utf8.decoder)) {
        final lines = chunk.split('\n');

        for (final line in lines) {
          if (line.startsWith('event:')) {
            eventType = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            eventData = line.substring(5).trim();
          } else if (line.startsWith('id:')) {
            eventId = line.substring(3).trim();
          } else if (line.startsWith('retry:')) {
            retry = int.tryParse(line.substring(6).trim());
          } else if (line.trim().isEmpty && eventData.isNotEmpty) {
            yield SseEvent(
              event: eventType,
              data: eventData,
              id: eventId,
              retry: retry,
            );
            eventType = 'message';
            eventData = '';
            eventId = null;
            retry = null;
          }
        }
      }
    } finally {
      _isConnected = false;
    }
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _isConnected = false;
  }
}
