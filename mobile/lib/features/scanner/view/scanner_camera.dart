import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Batas kamera; test mengganti preview dan kontrol tanpa perangkat keras.
abstract class ScannerCamera extends ChangeNotifier {
  bool get supported;
  bool get running;
  bool get requesting;
  bool get denied;
  bool get torchAvailable;
  bool get torchOn;
  String? get error;
  Widget preview(ValueChanged<String> onCode);
  Future<void> start();
  Future<void> stop();
  Future<void> toggleTorch();
  Future<void> close();
}

class AndroidScannerCamera extends ScannerCamera {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );
  bool _requesting = false;
  String? _error;
  bool _denied = false;

  AndroidScannerCamera() {
    _controller.addListener(notifyListeners);
  }

  @override
  bool get supported => !kIsWeb && Platform.isAndroid;
  @override
  bool get running => _controller.value.isRunning;
  @override
  bool get requesting => _requesting;
  @override
  bool get denied => _denied;
  @override
  String? get error =>
      _error ??
      (_controller.value.error != null
          ? 'Kamera bermasalah. Coba lagi atau cari produk manual.'
          : null);
  @override
  bool get torchAvailable =>
      running && _controller.value.torchState != TorchState.unavailable;
  @override
  bool get torchOn => _controller.value.torchState == TorchState.on;

  @override
  Widget preview(ValueChanged<String> onCode) => supported
      ? MobileScanner(
          controller: _controller,
          useAppLifecycleState: false,
          onDetect: (capture) {
            for (final barcode in capture.barcodes) {
              final raw = barcode.rawValue;
              if (raw != null && raw.trim().isNotEmpty) {
                onCode(raw);
                break;
              }
            }
          },
          onDetectError: (_, _) => _fail(false),
          errorBuilder: (_, _) => const SizedBox.expand(),
        )
      : const SizedBox.expand();

  void _fail(bool denied) {
    _denied = denied;
    _error = denied
        ? 'Izin kamera ditolak. Coba izinkan kembali. Jika dialog tidak muncul, buka Pengaturan Android > Aplikasi > RyanGunshop > Izin > Kamera, lalu pilih Izinkan.'
        : 'Kamera gagal dibuka. Tutup aplikasi lain yang memakai kamera, lalu coba lagi.';
    notifyListeners();
  }

  @override
  Future<void> start() async {
    if (!supported || running || _requesting) return;
    _requesting = true;
    _denied = false;
    _error = null;
    notifyListeners();
    try {
      await _controller.start();
      final failure = _controller.value.error;
      if (failure != null) {
        _fail(failure.errorCode == MobileScannerErrorCode.permissionDenied);
      }
    } on MobileScannerException catch (e) {
      _fail(e.errorCode == MobileScannerErrorCode.permissionDenied);
    } catch (_) {
      _fail(false);
    } finally {
      _requesting = false;
      notifyListeners();
    }
  }

  @override
  Future<void> stop() async {
    if (!supported) return;
    try {
      await _controller.stop();
    } catch (_) {
      _fail(false);
    }
  }

  @override
  Future<void> toggleTorch() async {
    if (!torchAvailable) return;
    try {
      await _controller.toggleTorch();
    } catch (_) {
      _fail(false);
    }
  }

  @override
  Future<void> close() async {
    _controller.removeListener(notifyListeners);
    await _controller.dispose();
    dispose();
  }
}
