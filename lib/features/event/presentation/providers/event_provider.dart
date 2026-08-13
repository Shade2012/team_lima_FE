import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/event_model.dart';
import '../../data/models/create_event_request.dart';
import '../../data/models/update_event_request.dart';
import '../../data/repositories/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

// ==================== My Events State ====================

class MyEventsState {
  final List<Event> events;
  final bool isLoading;
  final String? error;

  MyEventsState({this.events = const [], this.isLoading = false, this.error});

  MyEventsState copyWith({
    List<Event>? events,
    bool? isLoading,
    String? error,
  }) {
    return MyEventsState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyEventsNotifier extends Notifier<MyEventsState> {
  @override
  MyEventsState build() {
    Future.microtask(() => loadMyEvents());
    return MyEventsState();
  }

  Future<void> loadMyEvents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(eventRepositoryProvider);
      final events = await repository.getMyEvents();
      state = state.copyWith(events: events, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.deleteEvent(id);
      state = state.copyWith(
        events: state.events.where((e) => e.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final myEventsProvider = NotifierProvider<MyEventsNotifier, MyEventsState>(() {
  return MyEventsNotifier();
});

// ==================== Event Detail State ====================

class EventDetailState {
  final Event? event;
  final bool isLoading;
  final String? error;

  EventDetailState({this.event, this.isLoading = false, this.error});

  EventDetailState copyWith({Event? event, bool? isLoading, String? error}) {
    return EventDetailState(
      event: event ?? this.event,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EventDetailNotifier extends Notifier<EventDetailState> {
  @override
  EventDetailState build() {
    return EventDetailState();
  }

  Future<void> loadEvent(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(eventRepositoryProvider);
      final event = await repository.getEventDetail(id);
      state = state.copyWith(event: event, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void reset() {
    state = EventDetailState();
  }
}

final eventDetailProvider =
    NotifierProvider<EventDetailNotifier, EventDetailState>(() {
      return EventDetailNotifier();
    });

// ==================== Create Event State ====================

class CreateEventState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  CreateEventState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  CreateEventState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return CreateEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class CreateEventNotifier extends Notifier<CreateEventState> {
  @override
  CreateEventState build() {
    return CreateEventState();
  }

  Future<bool> createEvent(CreateEventRequest request) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.createEvent(request);
      state = state.copyWith(isLoading: false, isSuccess: true);
      ref.read(myEventsProvider.notifier).loadMyEvents();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = CreateEventState();
  }
}

final createEventProvider =
    NotifierProvider<CreateEventNotifier, CreateEventState>(() {
      return CreateEventNotifier();
    });

// ==================== Update Event State ====================

class UpdateEventState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  UpdateEventState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  UpdateEventState copyWith({bool? isLoading, String? error, bool? isSuccess}) {
    return UpdateEventState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class UpdateEventNotifier extends Notifier<UpdateEventState> {
  @override
  UpdateEventState build() {
    return UpdateEventState();
  }

  Future<bool> updateEvent(String id, UpdateEventRequest request) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repository = ref.read(eventRepositoryProvider);
      await repository.updateEvent(id, request);
      state = state.copyWith(isLoading: false, isSuccess: true);
      ref.read(eventDetailProvider.notifier).loadEvent(id);
      ref.read(myEventsProvider.notifier).loadMyEvents();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = UpdateEventState();
  }
}

final updateEventProvider =
    NotifierProvider<UpdateEventNotifier, UpdateEventState>(() {
      return UpdateEventNotifier();
    });
