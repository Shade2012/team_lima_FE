import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_five_fe/features/gate/presentation/pages/gate_operator/gate_operator_dashboard_page.dart';
import 'package:team_five_fe/features/gate/presentation/providers/gate_operator_dashboard_provider.dart';
import 'package:team_five_fe/features/gate/data/models/gate_model.dart';
import 'package:team_five_fe/features/event/data/models/event_model.dart';

class MockGateOperatorDashboardNotifier extends GateOperatorDashboardNotifier {
  @override
  GateOperatorDashboardState build() {
    final todayEvent = Event(
      id: 'event-001',
      organizerId: 'org-001',
      name: 'Neon Festival',
      isSeated: true,
      salesStartTime: DateTime.now().subtract(const Duration(days: 10)),
      salesEndTime: DateTime.now().add(const Duration(days: 20)),
      eventDate: DateTime.now(),
    );

    final futureEvent = Event(
      id: 'event-002',
      organizerId: 'org-001',
      name: 'Sonic Resonance',
      isSeated: false,
      salesStartTime: DateTime.now().add(const Duration(days: 5)),
      salesEndTime: DateTime.now().add(const Duration(days: 25)),
      eventDate: DateTime.now().add(const Duration(days: 30)),
    );

    return GateOperatorDashboardState(
      events: [
        GateOperatorEvent(
          gate: Gate(id: 'gate-001', name: 'North Gate'),
          event: todayEvent,
          isSelected: false,
        ),
        GateOperatorEvent(
          gate: Gate(id: 'gate-002', name: 'South Gate'),
          event: futureEvent,
          isSelected: false,
        ),
      ],
      scannedCount: 50,
      totalScans: 100,
    );
  }

  @override
  Future<void> loadAssignedGate() async {
    // Mock override to bypass network request
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

class EmptyGateOperatorDashboardNotifier extends GateOperatorDashboardNotifier {
  @override
  GateOperatorDashboardState build() {
    return GateOperatorDashboardState(events: []);
  }

  @override
  Future<void> loadAssignedGate() async {}
}

class ErrorGateOperatorDashboardNotifier extends GateOperatorDashboardNotifier {
  @override
  GateOperatorDashboardState build() {
    return GateOperatorDashboardState(
      error: 'Anda belum ditugaskan ke Gate manapun',
    );
  }

  @override
  Future<void> loadAssignedGate() async {}
}

void main() {
  group('Gate Operator Pages Widget Tests', () {
    testWidgets('GateOperatorDashboardPage renders header', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gateOperatorDashboardProvider.overrideWith(
              () => MockGateOperatorDashboardNotifier(),
            ),
          ],
          child: const MaterialApp(home: GateOperatorDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gate Operator'), findsOneWidget);
    });

    testWidgets(
      'GateOperatorDashboardPage renders tab bar with Active and Upcoming',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gateOperatorDashboardProvider.overrideWith(
                () => MockGateOperatorDashboardNotifier(),
              ),
            ],
            child: const MaterialApp(home: GateOperatorDashboardPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
      },
    );

    testWidgets('GateOperatorDashboardPage shows scan progress card', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gateOperatorDashboardProvider.overrideWith(
              () => MockGateOperatorDashboardNotifier(),
            ),
          ],
          child: const MaterialApp(home: GateOperatorDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Scan Progress'), findsOneWidget);
      expect(find.text('Scanned'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('GateOperatorDashboardPage displays active event card', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gateOperatorDashboardProvider.overrideWith(
              () => MockGateOperatorDashboardNotifier(),
            ),
          ],
          child: const MaterialApp(home: GateOperatorDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Neon Festival'), findsOneWidget);
      expect(find.text('Select to Scan'), findsOneWidget);
    });

    testWidgets('GateOperatorDashboardPage shows empty state when no events', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gateOperatorDashboardProvider.overrideWith(
              () => EmptyGateOperatorDashboardNotifier(),
            ),
          ],
          child: const MaterialApp(home: GateOperatorDashboardPage()),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No active events'), findsOneWidget);
    });

    testWidgets(
      'GateOperatorDashboardPage shows error state with retry button',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gateOperatorDashboardProvider.overrideWith(
                () => ErrorGateOperatorDashboardNotifier(),
              ),
            ],
            child: const MaterialApp(home: GateOperatorDashboardPage()),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Anda belum ditugaskan ke Gate manapun'),
          findsOneWidget,
        );
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'GateOperatorDashboardPage select event shows Scan Tickets button',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              gateOperatorDashboardProvider.overrideWith(
                () => MockGateOperatorDashboardNotifier(),
              ),
            ],
            child: const MaterialApp(home: GateOperatorDashboardPage()),
          ),
        );

        await tester.pumpAndSettle();

        // Tap Select to Scan to select the event
        await tester.tap(find.text('Select to Scan'));
        await tester.pumpAndSettle();

        // Should now show Scan Tickets button
        expect(find.text('Scan Tickets'), findsOneWidget);
      },
    );
  });
}
