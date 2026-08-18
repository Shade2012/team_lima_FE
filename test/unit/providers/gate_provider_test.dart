import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/gate/presentation/providers/scanner_provider.dart';
import 'package:team_five_fe/features/gate/presentation/providers/gate_operator_dashboard_provider.dart';
import 'package:team_five_fe/features/gate/data/models/gate_model.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';

class MockScannerNotifier extends ScannerNotifier {
  @override
  ScannerState build() {
    return ScannerState();
  }

  @override
  Future<void> processQrCode(String qrData) async {
    state = state.copyWith(isProcessing: true);

    // Simulate successful scan
    if (qrData == 'VALID_TICKET') {
      final result = ScanResult(
        isValid: true,
        message: 'Ticket scanned successfully',
      );
      state = state.copyWith(isProcessing: false, currentResult: result);
    } else {
      final result = ScanResult(isValid: false, errorMessage: 'Invalid ticket');
      state = state.copyWith(isProcessing: false, currentResult: result);
    }
  }
}

class MockGateOperatorDashboardNotifier extends GateOperatorDashboardNotifier {
  @override
  GateOperatorDashboardState build() {
    return GateOperatorDashboardState();
  }

  @override
  Future<void> loadAssignedGate() async {
    state = state.copyWith(isLoading: true, error: null);

    final gate = Gate(id: 'gate-001', name: 'North Gate', eventId: 'event-001');

    final event = Event(
      id: 'event-001',
      organizerId: 'org-001',
      name: 'Neon Festival',
      isSeated: true,
      salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
      salesEndTime: DateTime.now().add(const Duration(days: 20)),
      eventDate: DateTime.now(),
    );

    final operatorEvent = GateOperatorEvent(
      gate: gate,
      event: event,
      isSelected: false,
    );

    state = state.copyWith(
      isLoading: false,
      events: [operatorEvent],
      scannedCount: 50,
      totalScans: 100,
    );
  }

  @override
  void selectEvent(String eventId) {
    state = state.copyWith(
      events: state.events.map((e) {
        return e.copyWith(isSelected: e.id == eventId);
      }).toList(),
    );
  }
}

void main() {
  group('Scanner Provider Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('ScannerState initializes with default values', () {
      final state = container.read(scannerProvider);

      expect(state.gateName, '');
      expect(state.eventName, '');
      expect(state.isProcessing, false);
      expect(state.currentResult, isNull);
    });

    test('ScannerState copyWith updates gateName and eventName', () {
      final state = ScannerState();
      final updated = state.copyWith(
        gateName: 'North Gate',
        eventName: 'Festival',
      );

      expect(updated.gateName, 'North Gate');
      expect(updated.eventName, 'Festival');
    });

    test('ScannerState copyWith clearResult removes currentResult', () {
      final result = ScanResult(isValid: true, message: 'Success');
      final state = ScannerState(currentResult: result);

      expect(state.currentResult, isNotNull);

      final cleared = state.copyWith(clearResult: true);

      expect(cleared.currentResult, isNull);
    });

    test('ScanResult stores isValid, message, and errorMessage', () {
      final successResult = ScanResult(isValid: true, message: 'OK');
      final errorResult = ScanResult(isValid: false, errorMessage: 'Invalid');

      expect(successResult.isValid, true);
      expect(successResult.message, 'OK');
      expect(successResult.errorMessage, isNull);

      expect(errorResult.isValid, false);
      expect(errorResult.errorMessage, 'Invalid');
    });

    test('ScannerNotifier init sets gate and event names', () {
      final notifier = container.read(scannerProvider.notifier);

      notifier.init(gateName: 'South Gate', eventName: 'Rock Concert');

      final state = container.read(scannerProvider);

      expect(state.gateName, 'South Gate');
      expect(state.eventName, 'Rock Concert');
    });

    test('ScannerNotifier resetScanner clears currentResult', () {
      final notifier = container.read(scannerProvider.notifier);

      // First set a result
      notifier.init(gateName: 'Gate', eventName: 'Event');

      // Reset
      notifier.resetScanner();

      final state = container.read(scannerProvider);
      expect(state.currentResult, isNull);
    });
  });

  group('GateOperatorDashboard Provider Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('GateOperatorDashboardState initializes with default values', () {
      final state = container.read(gateOperatorDashboardProvider);

      expect(state.events, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.scannedCount, 0);
      expect(state.totalScans, 0);
    });

    test('scanProgress calculates correctly', () {
      final state = GateOperatorDashboardState(
        scannedCount: 50,
        totalScans: 100,
      );

      expect(state.scanProgress, 0.5);
    });

    test('scanProgress returns 0 when totalScans is 0', () {
      final state = GateOperatorDashboardState(scannedCount: 0, totalScans: 0);

      expect(state.scanProgress, 0.0);
    });

    test('GateOperatorDashboardState copyWith preserves values', () {
      final gate = Gate(id: 'g1', name: 'Gate 1');
      final event = Event(
        id: 'e1',
        organizerId: 'o1',
        name: 'Event 1',
        isSeated: false,
        salesStartTime: DateTime.now(),
        salesEndTime: DateTime.now(),
        eventDate: DateTime.now(),
      );

      final operatorEvent = GateOperatorEvent(gate: gate, event: event);

      final state = GateOperatorDashboardState(
        scannedCount: 25,
        totalScans: 50,
      );

      final updated = state.copyWith(events: [operatorEvent]);

      expect(updated.events.length, 1);
      expect(updated.scannedCount, 25);
      expect(updated.totalScans, 50);
    });

    test('GateOperatorEvent computed properties work correctly', () {
      final gate = Gate(id: 'g1', name: 'North Gate');
      final event = Event(
        id: 'e1',
        organizerId: 'o1',
        name: 'Today Festival',
        isSeated: true,
        salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
        salesEndTime: DateTime.now().add(const Duration(days: 20)),
        eventDate: DateTime.now(),
      );

      final operatorEvent = GateOperatorEvent(
        gate: gate,
        event: event,
        isSelected: false,
      );

      expect(operatorEvent.id, 'g1');
      expect(operatorEvent.gateName, 'North Gate');
      expect(operatorEvent.eventName, 'Today Festival');
      expect(operatorEvent.isActive, true);
      expect(operatorEvent.isSelected, false);
    });

    test('GateOperatorEvent copyWith preserves isSelected', () {
      final gate = Gate(id: 'g1', name: 'Gate');
      final event = Event(
        id: 'e1',
        organizerId: 'o1',
        name: 'Event',
        isSeated: false,
        salesStartTime: DateTime.now(),
        salesEndTime: DateTime.now(),
        eventDate: DateTime.now(),
      );

      final original = GateOperatorEvent(
        gate: gate,
        event: event,
        isSelected: false,
      );

      final selected = original.copyWith(isSelected: true);

      expect(selected.isSelected, true);
      expect(original.isSelected, false);
    });

    test(
      'GateOperatorDashboardNotifier selectEvent toggles selection',
      () async {
        final container2 = ProviderContainer(
          overrides: [
            gateOperatorDashboardProvider.overrideWith(
              () => MockGateOperatorDashboardNotifier(),
            ),
          ],
        );
        addTearDown(container2.dispose);

        final notifier = container2.read(
          gateOperatorDashboardProvider.notifier,
        );

        // Load events first
        await notifier.loadAssignedGate();

        notifier.selectEvent('gate-001');

        final state = container2.read(gateOperatorDashboardProvider);
        expect(state.events.first.isSelected, true);
      },
    );
  });
}
