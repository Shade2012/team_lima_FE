import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/gate/data/models/gate_model.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';

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
  int get scannedCount => gate.scannedCount;
  int get totalAttendees => 2000;
  bool get isActive {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(event.eventDate.year, event.eventDate.month, event.eventDate.day);
    return eventDay.isAtSameMomentAs(today);
  }

  GateOperatorEvent copyWith({
    Gate? gate,
    Event? event,
    bool? isSelected,
  }) {
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

class GateOperatorDashboardNotifier extends Notifier<GateOperatorDashboardState> {
  @override
  GateOperatorDashboardState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dummyScans1 = List.generate(
      1240,
      (i) => AdmissionScan(
        id: 'scan_$i',
        scannedAt: now,
        ticketId: 'ticket_$i',
        gateOperatorId: 'operator_1',
        gateId: 'gate_1',
      ),
    );

    final dummyGates = [
      Gate(
        id: 'gate_1',
        name: 'Gate 4',
        eventId: 'event_1',
        scans: dummyScans1,
      ),
      Gate(
        id: 'gate_2',
        name: 'Gate 2',
        eventId: 'event_2',
        scans: [],
      ),
      Gate(
        id: 'gate_3',
        name: 'Gate 1',
        eventId: 'event_3',
        scans: [],
      ),
      Gate(
        id: 'gate_4',
        name: 'Gate 3',
        eventId: 'event_4',
        scans: [],
      ),
    ];

    final dummyEvents = [
      Event(
        id: 'event_1',
        organizerId: 'org_1',
        name: 'Neon Jungle Festival',
        isSeated: false,
        salesStartTime: today,
        salesEndTime: today.add(const Duration(days: 1)),
        eventDate: today,
      ),
      Event(
        id: 'event_2',
        organizerId: 'org_1',
        name: 'Cosmic Night Live',
        isSeated: false,
        salesStartTime: today,
        salesEndTime: today.add(const Duration(days: 1)),
        eventDate: today,
      ),
      Event(
        id: 'event_3',
        organizerId: 'org_1',
        name: 'Midnight Echoes',
        isSeated: true,
        salesStartTime: today.add(const Duration(days: 7)),
        salesEndTime: today.add(const Duration(days: 21)),
        eventDate: today.add(const Duration(days: 14)),
      ),
      Event(
        id: 'event_4',
        organizerId: 'org_1',
        name: 'Summer Beats Festival',
        isSeated: false,
        salesStartTime: today.add(const Duration(days: 15)),
        salesEndTime: today.add(const Duration(days: 45)),
        eventDate: today.add(const Duration(days: 30)),
      ),
    ];

    final dummyOperatorEvents = [
      GateOperatorEvent(
        gate: dummyGates[0],
        event: dummyEvents[0],
        isSelected: true,
      ),
      GateOperatorEvent(
        gate: dummyGates[1],
        event: dummyEvents[1],
      ),
      GateOperatorEvent(
        gate: dummyGates[2],
        event: dummyEvents[2],
      ),
      GateOperatorEvent(
        gate: dummyGates[3],
        event: dummyEvents[3],
      ),
    ];

    return GateOperatorDashboardState(
      events: dummyOperatorEvents,
    );
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
