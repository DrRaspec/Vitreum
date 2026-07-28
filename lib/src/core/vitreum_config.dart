import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/vitreum_method_channel.dart';
import 'vitreum_capabilities.dart';

/// Parameters used only by Flutter simulated and solid fallbacks.
@immutable
class VitreumFallbackStyle {
  const VitreumFallbackStyle({
    this.blurSigma = 14,
    this.surfaceOpacity = 0.16,
    this.refractionStrength = 0.04,
    this.chromaticAberration = 0.008,
    this.highlightStrength = 0.22,
    this.borderOpacity = 0.28,
    this.shadowStrength = 0.16,
  });

  final double blurSigma;
  final double surfaceOpacity;
  final double refractionStrength;
  final double chromaticAberration;
  final double highlightStrength;
  final double borderOpacity;
  final double shadowStrength;

  /// Returns values clamped to safe renderer ranges.
  VitreumFallbackStyle validated() => VitreumFallbackStyle(
    blurSigma: _finiteClamp(blurSigma, 0, 40, 14),
    surfaceOpacity: _finiteClamp(surfaceOpacity, 0, 1, 0.16),
    refractionStrength: _finiteClamp(refractionStrength, 0, 0.2, 0.04),
    chromaticAberration: _finiteClamp(chromaticAberration, 0, 0.05, 0.008),
    highlightStrength: _finiteClamp(highlightStrength, 0, 1, 0.22),
    borderOpacity: _finiteClamp(borderOpacity, 0, 1, 0.28),
    shadowStrength: _finiteClamp(shadowStrength, 0, 1, 0.16),
  );

  VitreumFallbackStyle copyWith({
    double? blurSigma,
    double? surfaceOpacity,
    double? refractionStrength,
    double? chromaticAberration,
    double? highlightStrength,
    double? borderOpacity,
    double? shadowStrength,
  }) => VitreumFallbackStyle(
    blurSigma: blurSigma ?? this.blurSigma,
    surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    refractionStrength: refractionStrength ?? this.refractionStrength,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
    highlightStrength: highlightStrength ?? this.highlightStrength,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    shadowStrength: shadowStrength ?? this.shadowStrength,
  );

  @override
  bool operator ==(Object other) =>
      other is VitreumFallbackStyle &&
      other.blurSigma == blurSigma &&
      other.surfaceOpacity == surfaceOpacity &&
      other.refractionStrength == refractionStrength &&
      other.chromaticAberration == chromaticAberration &&
      other.highlightStrength == highlightStrength &&
      other.borderOpacity == borderOpacity &&
      other.shadowStrength == shadowStrength;

  @override
  int get hashCode => Object.hash(
    blurSigma,
    surfaceOpacity,
    refractionStrength,
    chromaticAberration,
    highlightStrength,
    borderOpacity,
    shadowStrength,
  );
}

double _finiteClamp(double value, double min, double max, double fallback) =>
    value.isFinite ? value.clamp(min, max) : fallback;

/// Debug-only visual diagnostics.
@immutable
class VitreumDebugOptions {
  const VitreumDebugOptions({
    this.showBounds = false,
    this.showBackendLabel = false,
    this.logBackendSelection = false,
  });

  final bool showBounds;
  final bool showBackendLabel;
  final bool logBackendSelection;
}

/// Package-level capability entry point.
abstract final class Vitreum {
  static VitreumPlatformInterface platform = const VitreumMethodChannel();

  /// Returns a defensive capability snapshot and never throws for unsupported
  /// platforms or missing plugin registration.
  static Future<VitreumCapabilities> getCapabilities() async {
    try {
      final capabilities = await platform.getCapabilities();
      return capabilities.copyWith(
        shaderAvailable: !kIsWeb && ui.ImageFilter.isShaderFilterSupported,
      );
    } on PlatformException {
      return VitreumMethodChannel.fallbackCapabilities();
    } on MissingPluginException {
      return VitreumMethodChannel.fallbackCapabilities();
    }
  }
}

/// Internal contract exposed here only to permit package tests to replace it.
abstract interface class VitreumPlatformInterface {
  Future<VitreumCapabilities> getCapabilities();
}
