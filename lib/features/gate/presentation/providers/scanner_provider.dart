import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanResult {
  final bool isValid;
  final String ticketType;
  final String attendeeName;
  final String? attendeeEmail;

  ScanResult({
    required this.isValid,
    required this.ticketType,
    required this.attendeeName,
    this.attendeeEmail,
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

    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 1));

    // Dummy scan result
    final result = ScanResult(
      isValid: true,
      ticketType: 'VIP PASS',
      attendeeName: 'Alex Mercer',
      attendeeEmail: 'alex@example.com',
    );

    state = state.copyWith(
      isProcessing: false,
      currentResult: result,
    );
  }

  void resetScanner() {
    state = state.copyWith(clearResult: true);
  }
}

final scannerProvider = NotifierProvider<ScannerNotifier, ScannerState>(
  () => ScannerNotifier(),
);
