import 'package:dio/dio.dart';

/// Optional In-App Mock Interceptor for Flutter local testing without Node.js server.
class MockInterceptor extends Interceptor {
  final bool enabled;

  MockInterceptor({this.enabled = false});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!enabled) {
      return handler.next(options);
    }

    final path = options.path;
    final method = options.method.toUpperCase();

    // Mock Login
    if (path.contains('/users/login') && method == 'POST') {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            "message": "Success",
            "data": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.mock_token_flutter",
          },
        ),
      );
    }

    // Mock Get Events
    if (path.contains('/events') && method == 'GET') {
      return handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            "message": "Success",
            "data": [
              {
                "id": "019146a0-7d1e-7abc-9a12-abcdef123456",
                "organizerId": "019146a0-0000-7abc-0000-abcdef000001",
                "name": "Konser Sheila On 7 Jakarta 2026",
                "isSeated": true,
                "salesStartTime": "2026-09-01T10:00:00.000Z",
                "salesEndTime": "2026-09-15T23:59:59.000Z",
                "eventDate": "2026-10-01T19:00:00.000Z",
                "refundEndDate": "2026-09-25T23:59:59.000Z",
                "refundPolicy":
                    "Refund dapat diajukan maksimal 7 hari sebelum event.",
                "refundPercentage": 80,
                "createdAt": "2026-08-12T10:00:00.000Z",
                "updatedAt": "2026-08-12T10:00:00.000Z",
              },
            ],
          },
        ),
      );
    }

    return handler.next(options);
  }
}
