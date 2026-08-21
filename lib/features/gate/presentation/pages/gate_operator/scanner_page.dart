import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:veloce/core/theme/app_colors.dart';
import 'package:veloce/core/theme/app_text_styles.dart';
import 'package:veloce/features/gate/presentation/providers/scanner_provider.dart';

class ScannerPage extends ConsumerStatefulWidget {
  final String gateName;
  final String eventName;

  const ScannerPage({
    super.key,
    required this.gateName,
    required this.eventName,
  });

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(scannerProvider.notifier)
          .init(gateName: widget.gateName, eventName: widget.eventName);
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode != null && barcode.rawValue != null) {
      setState(() => _isProcessing = true);
      ref.read(scannerProvider.notifier).processQrCode(barcode.rawValue!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(onDetect: _onDetect),
          _buildOverlay(scannerState),
          _buildHeader(),
          if (scannerState.currentResult != null)
            _buildResultBottomSheet(scannerState, () {
              setState(() => _isProcessing = false);
            }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 12,
          20,
          16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.gateName,
                    style: AppTextStyles.title.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.eventName.toUpperCase(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(ScannerState scannerState) {
    return IgnorePointer(
      child: Column(
        children: [
          Expanded(
            flex: 2,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          SizedBox(
            height: 280,
            child: Row(
              children: [
                Expanded(
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
                _buildScanFrame(scannerState),
                Expanded(
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame(ScannerState scannerState) {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          _buildCorner(Alignment.topLeft, true, true),
          _buildCorner(Alignment.topRight, true, false),
          _buildCorner(Alignment.bottomLeft, false, true),
          _buildCorner(Alignment.bottomRight, false, false),
          if (scannerState.isProcessing)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment, bool isTop, bool isLeft) {
    return Positioned(
      top: isTop ? 0 : null,
      bottom: isTop ? null : 0,
      left: isLeft ? 0 : null,
      right: isLeft ? null : 0,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            bottom: isTop
                ? BorderSide.none
                : const BorderSide(color: AppColors.primary, width: 4),
            left: isLeft
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            right: isLeft
                ? BorderSide.none
                : const BorderSide(color: AppColors.primary, width: 4),
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(8) : Radius.zero,
            topRight: isTop && !isLeft ? const Radius.circular(8) : Radius.zero,
            bottomLeft: !isTop && isLeft
                ? const Radius.circular(8)
                : Radius.zero,
            bottomRight: !isTop && !isLeft
                ? const Radius.circular(8)
                : Radius.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildResultBottomSheet(
    ScannerState scannerState,
    VoidCallback onScanNext,
  ) {
    final result = scannerState.currentResult!;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: result.isValid
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                result.isValid ? Icons.check : Icons.close,
                color: result.isValid ? AppColors.success : AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              result.isValid ? 'Scan Successful' : 'Scan Failed',
              style: AppTextStyles.title.copyWith(
                fontSize: 18,
                color: result.isValid ? AppColors.success : AppColors.danger,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result.isValid
                    ? AppColors.success.withValues(alpha: 0.05)
                    : AppColors.danger.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result.isValid
                    ? (result.message.isNotEmpty ? result.message : 'Success')
                    : (result.errorMessage ?? 'Unknown error'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: result.isValid ? AppColors.success : AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(scannerProvider.notifier).resetScanner();
                  onScanNext();
                },
                icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                label: Text(
                  'Scan Next Ticket',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
