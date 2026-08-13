import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/gate_model.dart';
import '../../data/models/create_gate_request.dart';
import '../../data/models/update_gate_request.dart';
import '../../data/models/gate_operator_request.dart';
import '../../data/repositories/gate_repository.dart';
import '../../../auth/data/models/user_model.dart';

final gateRepositoryProvider = Provider<GateRepository>((ref) {
  return GateRepository();
});

// ==================== Gates List State ====================

class GatesState {
  final List<Gate> gates;
  final bool isLoading;
  final String? error;

  GatesState({this.gates = const [], this.isLoading = false, this.error});

  GatesState copyWith({
    List<Gate>? gates,
    bool? isLoading,
    String? error,
  }) {
    return GatesState(
      gates: gates ?? this.gates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class GatesNotifier extends Notifier<GatesState> {
  String _eventId = '';

  @override
  GatesState build() {
    return GatesState();
  }

  void setEventId(String eventId) {
    _eventId = eventId;
    loadGates();
  }

  Future<void> loadGates() async {
    if (_eventId.isEmpty) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(gateRepositoryProvider);
      final gates = await repository.getGatesByEvent(_eventId);
      state = state.copyWith(gates: gates, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<bool> createGate(CreateGateRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(gateRepositoryProvider);
      final gate = await repository.createGate(request);
      state = state.copyWith(isLoading: false, gates: [...state.gates, gate]);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> updateGate(String id, UpdateGateRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(gateRepositoryProvider);
      final updatedGate = await repository.updateGate(id, request);
      state = state.copyWith(
        isLoading: false,
        gates: state.gates.map((g) => g.id == id ? updatedGate : g).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> deleteGate(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final repository = ref.read(gateRepositoryProvider);
      await repository.deleteGate(id);
      state = state.copyWith(
        isLoading: false,
        gates: state.gates.where((g) => g.id != id).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final gatesProvider = NotifierProvider<GatesNotifier, GatesState>(() {
  return GatesNotifier();
});

// ==================== Gate Operator State ====================

class GateOperatorState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;
  final List<UserModel> createdOperators;

  GateOperatorState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.createdOperators = const [],
  });

  GateOperatorState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    List<UserModel>? createdOperators,
  }) {
    return GateOperatorState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      createdOperators: createdOperators ?? this.createdOperators,
    );
  }
}

class GateOperatorNotifier extends Notifier<GateOperatorState> {
  @override
  GateOperatorState build() {
    return GateOperatorState();
  }

  Future<bool> registerGateOperator(GateOperatorRequest request) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);
    try {
      final repository = ref.read(gateRepositoryProvider);
      final operators = await repository.registerGateOperator(request);
      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        createdOperators: [...state.createdOperators, ...operators],
      );
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
    state = GateOperatorState();
  }
}

final gateOperatorProvider =
    NotifierProvider<GateOperatorNotifier, GateOperatorState>(() {
  return GateOperatorNotifier();
});
