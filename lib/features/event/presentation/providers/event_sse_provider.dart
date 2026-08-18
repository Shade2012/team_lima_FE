import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/event_sse_repository.dart';

final eventSseRepositoryProvider = Provider<EventSseRepository>((ref) {
  return EventSseRepository();
});

final dashboardSseProvider = StreamProvider.autoDispose
    .family<DashboardUpdateEvent, String>((ref, eventId) {
      final repository = ref.read(eventSseRepositoryProvider);
      ref.onDispose(() => repository.disconnect());
      return repository.watchDashboard(eventId);
    });
