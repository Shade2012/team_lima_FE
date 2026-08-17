import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/gate/data/models/gate_model.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';
import 'gate_provider.dart';

class GateOperatorEvent {
  final Gate gate;
  final Event event;
  final bool isSelected;

  GateOperatorEvent({
    required this.gate,
    required this.event,
    this.isSelected = false,
  });

  String get id => gate.id;
  String get gateName => gate.name;
  String get eventName => event.name;
  DateTime get eventDate => event.eventDate;
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
    );
    return eventDay.isAtSameMomentAs(today);
  }

  GateOperatorEvent copyWith({Gate? gate, Event? event, bool? isSelected}) {
    return GateOperatorEvent(
      gate: gate ?? this.gate,
      event: event ?? this.event,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class GateOperatorDashboardState {
  final List<GateOperatorEvent> events;
  final bool isLoading;
  final String? error;

  GateOperatorDashboardState({
    this.events = const [],
    this.isLoading = false,
    this.error,
  });

  GateOperatorDashboardState copyWith({
    List<GateOperatorEvent>? events,
    bool? isLoading,
    String? error,
  }) {
    return GateOperatorDashboardState(
      events: events ?? this.events,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GateOperatorDashboardNotifier
    extends Notifier<GateOperatorDashboardState> {
  @override
  GateOperatorDashboardState build() {
    return GateOperatorDashboardState();
  }

  Future<void> loadAssignedGate() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(gateRepositoryProvider);
      final result = await repository.getAssignedGate();
      if (result == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Anda belum ditugaskan ke Gate manapun',
        );
        return;
      }
      final (gate, event) = result;
      final operatorEvent = GateOperatorEvent(
        gate: gate,
        event: event,
        isSelected: state.events.isNotEmpty && state.events.first.isSelected,
      );
      state = state.copyWith(
        isLoading: false,
        events: [operatorEvent],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void selectEvent(String eventId) {
    state = state.copyWith(
      events: state.events.map((e) {
        return e.copyWith(isSelected: e.id == eventId);
      }).toList(),
    );
  }
}

final gateOperatorDashboardProvider =
    NotifierProvider<GateOperatorDashboardNotifier, GateOperatorDashboardState>(
      () => GateOperatorDashboardNotifier(),
    );
