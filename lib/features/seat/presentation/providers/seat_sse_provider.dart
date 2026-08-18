import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/seat_sse_repository.dart';

final seatSseRepositoryProvider = Provider<SeatSseRepository>((ref) {
  return SeatSseRepository();
});

final seatSseProvider = StreamProvider.autoDispose
    .family<SeatUpdateEvent, String>((ref, eventId) {
      final repository = ref.read(seatSseRepositoryProvider);
      ref.onDispose(() => repository.disconnect());
      return repository.watchSeats(eventId);
    });
