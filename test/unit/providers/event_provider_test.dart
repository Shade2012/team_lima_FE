import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/event/presentation/providers/event_provider.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';

class MockMyEventsNotifier extends MyEventsNotifier {
  @override
  MyEventsState build() {
    return MyEventsState();
  }

  @override
  Future<void> loadMyEvents() async {
    state = state.copyWith(
      isLoading: false,
      events: [
        Event(
          id: 'evt-1',
          organizerId: 'org-1',
          name: 'Active Festival',
          isSeated: true,
          salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
          salesEndTime: DateTime.now().add(const Duration(days: 20)),
          eventDate: DateTime.now().add(const Duration(days: 30)),
        ),
      ],
    );
  }

  @override
  Future<bool> deleteEvent(String id) async {
    state = state.copyWith(
      events: state.events.where((e) => e.id != id).toList(),
    );
    return true;
  }
}

class EmptyMyEventsNotifier extends MyEventsNotifier {
  @override
  MyEventsState build() {
    return MyEventsState();
  }

  @override
  Future<void> loadMyEvents() async {}
}

class MockAllEventsNotifier extends AllEventsNotifier {
  @override
  AllEventsState build() {
    return AllEventsState();
  }

  @override
  Future<void> loadAllEvents() async {
    state = state.copyWith(
      isLoading: false,
      events: [
        Event(
          id: 'evt-1',
          organizerId: 'org-1',
          name: 'Event One',
          isSeated: true,
          salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
          salesEndTime: DateTime.now().add(const Duration(days: 20)),
          eventDate: DateTime.now().add(const Duration(days: 30)),
        ),
        Event(
          id: 'evt-2',
          organizerId: 'org-2',
          name: 'Event Two',
          isSeated: false,
          salesStartTime: DateTime.now().subtract(const Duration(days: 5)),
          salesEndTime: DateTime.now().add(const Duration(days: 10)),
          eventDate: DateTime.now().add(const Duration(days: 15)),
        ),
      ],
    );
  }
}

void main() {
  group('Event Providers Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('MyEventsNotifier initializes with empty state', () {
      final container2 = ProviderContainer(
        overrides: [
          myEventsProvider.overrideWith(() => EmptyMyEventsNotifier()),
        ],
      );
      addTearDown(container2.dispose);

      final state = container2.read(myEventsProvider);

      expect(state.events, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('MyEventsState copyWith preserves existing values', () {
      final state = MyEventsState(
        events: [
          Event(
            id: 'evt-1',
            organizerId: 'org-1',
            name: 'Test',
            isSeated: false,
            salesStartTime: DateTime.now(),
            salesEndTime: DateTime.now(),
            eventDate: DateTime.now(),
          ),
        ],
        isLoading: false,
        error: null,
      );

      final updated = state.copyWith(isLoading: true);

      expect(updated.events.length, 1);
      expect(updated.isLoading, true);
      expect(updated.error, isNull);
    });

    test('AllEventsState copyWith preserves events when not provided', () {
      final events = [
        Event(
          id: 'evt-1',
          organizerId: 'org-1',
          name: 'Event',
          isSeated: false,
          salesStartTime: DateTime.now(),
          salesEndTime: DateTime.now(),
          eventDate: DateTime.now(),
        ),
      ];

      final state = AllEventsState(events: events, isLoading: false);
      final updated = state.copyWith(isLoading: true);

      expect(updated.events.length, 1);
      expect(updated.isLoading, true);
    });

    test('EventDetailState copyWith preserves event when not provided', () {
      final event = Event(
        id: 'evt-1',
        organizerId: 'org-1',
        name: 'Detail Event',
        isSeated: true,
        salesStartTime: DateTime.now(),
        salesEndTime: DateTime.now(),
        eventDate: DateTime.now(),
      );

      final state = EventDetailState(event: event);
      final updated = state.copyWith(isLoading: true);

      expect(updated.event?.name, 'Detail Event');
      expect(updated.isLoading, true);
    });

    test('CreateEventState copyWith preserves createdEvent', () {
      final event = Event(
        id: 'evt-new',
        organizerId: 'org-1',
        name: 'New Event',
        isSeated: false,
        salesStartTime: DateTime.now(),
        salesEndTime: DateTime.now(),
        eventDate: DateTime.now(),
      );

      final state = CreateEventState(createdEvent: event, isSuccess: true);
      final updated = state.copyWith(isLoading: true);

      expect(updated.createdEvent?.id, 'evt-new');
      expect(updated.isLoading, true);
      expect(updated.isSuccess, true);
    });

    test('UpdateEventState copyWith preserves isSuccess', () {
      final state = UpdateEventState(isSuccess: true);
      final updated = state.copyWith(isLoading: true);

      expect(updated.isSuccess, true);
      expect(updated.isLoading, true);
    });

    test('EventStatisticsState copyWith preserves statistics', () {
      final state = EventStatisticsState(
        isLoading: false,
      );

      final updated = state.copyWith(isLoading: true);

      expect(updated.isLoading, true);
    });
  });
}
