import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gate_repository.dart';

final gateRepositoryProvider = Provider<GateRepository>((ref) {
  return GateRepository();
});

class ScanResult {
  final bool isValid;
  final String message;
  final String? errorMessage;

  ScanResult({
    required this.isValid,
    this.message = '',
    this.errorMessage,
  });
}

class ScannerState {
  final String gateName;
  final String eventName;
  final bool isProcessing;
  final ScanResult? currentResult;

  ScannerState({
    this.gateName = '',
    this.eventName = '',
    this.isProcessing = false,
    this.currentResult,
  });

  ScannerState copyWith({
    String? gateName,
    String? eventName,
    bool? isProcessing,
    ScanResult? currentResult,
    bool clearResult = false,
  }) {
    return ScannerState(
      gateName: gateName ?? this.gateName,
      eventName: eventName ?? this.eventName,
      isProcessing: isProcessing ?? this.isProcessing,
      currentResult: clearResult ? null : (currentResult ?? this.currentResult),
    );
  }
}

class ScannerNotifier extends Notifier<ScannerState> {
  @override
  ScannerState build() {
    return ScannerState();
  }

  void init({required String gateName, required String eventName}) {
    state = state.copyWith(
      gateName: gateName,
      eventName: eventName,
    );
  }

  Future<void> processQrCode(String qrData) async {
    if (state.isProcessing) return;

    state = state.copyWith(isProcessing: true);

    try {
      final repo = ref.read(gateRepositoryProvider);
      final responseMessage = await repo.scanTicket(qrData);

      final result = ScanResult(
        isValid: true,
        message: responseMessage,
      );

      state = state.copyWith(
        isProcessing: false,
        currentResult: result,
      );
    } catch (e) {
      final cleanMessage = e.toString().replaceAll('Exception: ', '');

      final result = ScanResult(
        isValid: false,
        errorMessage: cleanMessage,
      );

      state = state.copyWith(
        isProcessing: false,
        currentResult: result,
      );
    }
  }

  void resetScanner() {
    state = state.copyWith(clearResult: true);
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  () => ScannerNotifier(),
);
