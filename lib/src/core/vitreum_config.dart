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
    this.edgeWidth = 1,
    this.edgeColor = const ui.Color(0xFFFFFFFF),
    this.shadowStrength = 0.16,
    this.shadowBlurSigma = 8,
    this.shadowOffset = const ui.Offset(0, 3),
    this.shadowColor = const ui.Color(0xFF000000),
  });

  /// Standard deviation of the simulated backdrop blur.
  final double blurSigma;

  /// Opacity of the simulated tint surface before style adjustment.
  final double surfaceOpacity;

  /// Requested edge displacement for the optional high-quality shader.
  final double refractionStrength;

  /// Requested spectral separation for the optional high-quality shader.
  final double chromaticAberration;

  /// Strength of the simulated directional highlight.
  final double highlightStrength;

  /// Opacity multiplier for simulated edge lighting.
  final double borderOpacity;

  /// Width of simulated edge lighting. Set to zero to disable it.
  final double edgeWidth;

  /// Base color of simulated edge lighting.
  final ui.Color edgeColor;

  /// Opacity multiplier for the simulated ambient shadow.
  final double shadowStrength;

  /// Standard deviation of the simulated ambient shadow blur.
  final double shadowBlurSigma;

  /// Offset of the simulated ambient shadow.
  final ui.Offset shadowOffset;

  /// Base color of the simulated ambient shadow.
  final ui.Color shadowColor;

  /// Returns values clamped to safe renderer ranges.
  VitreumFallbackStyle validated() => VitreumFallbackStyle(
    blurSigma: _finiteClamp(blurSigma, 0, 40, 14),
    surfaceOpacity: _finiteClamp(surfaceOpacity, 0, 1, 0.16),
    refractionStrength: _finiteClamp(refractionStrength, 0, 0.2, 0.04),
    chromaticAberration: _finiteClamp(chromaticAberration, 0, 0.05, 0.008),
    highlightStrength: _finiteClamp(highlightStrength, 0, 1, 0.22),
    borderOpacity: _finiteClamp(borderOpacity, 0, 1, 0.28),
    edgeWidth: _finiteClamp(edgeWidth, 0, 8, 1),
    edgeColor: edgeColor,
    shadowStrength: _finiteClamp(shadowStrength, 0, 1, 0.16),
    shadowBlurSigma: _finiteClamp(shadowBlurSigma, 0, 40, 8),
    shadowOffset: ui.Offset(
      _finiteClamp(shadowOffset.dx, -40, 40, 0),
      _finiteClamp(shadowOffset.dy, -40, 40, 3),
    ),
    shadowColor: shadowColor,
  );

  /// Returns a copy with the supplied values replaced.
  VitreumFallbackStyle copyWith({
    double? blurSigma,
    double? surfaceOpacity,
    double? refractionStrength,
    double? chromaticAberration,
    double? highlightStrength,
    double? borderOpacity,
    double? edgeWidth,
    ui.Color? edgeColor,
    double? shadowStrength,
    double? shadowBlurSigma,
    ui.Offset? shadowOffset,
    ui.Color? shadowColor,
  }) => VitreumFallbackStyle(
    blurSigma: blurSigma ?? this.blurSigma,
    surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    refractionStrength: refractionStrength ?? this.refractionStrength,
    chromaticAberration: chromaticAberration ?? this.chromaticAberration,
    highlightStrength: highlightStrength ?? this.highlightStrength,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    edgeWidth: edgeWidth ?? this.edgeWidth,
    edgeColor: edgeColor ?? this.edgeColor,
    shadowStrength: shadowStrength ?? this.shadowStrength,
    shadowBlurSigma: shadowBlurSigma ?? this.shadowBlurSigma,
    shadowOffset: shadowOffset ?? this.shadowOffset,
    shadowColor: shadowColor ?? this.shadowColor,
  );

  /// Interpolates between two fallback styles.
  static VitreumFallbackStyle lerp(
    VitreumFallbackStyle a,
    VitreumFallbackStyle b,
    double t,
  ) => VitreumFallbackStyle(
    blurSigma: ui.lerpDouble(a.blurSigma, b.blurSigma, t)!,
    surfaceOpacity: ui.lerpDouble(a.surfaceOpacity, b.surfaceOpacity, t)!,
    refractionStrength: ui.lerpDouble(
      a.refractionStrength,
      b.refractionStrength,
      t,
    )!,
    chromaticAberration: ui.lerpDouble(
      a.chromaticAberration,
      b.chromaticAberration,
      t,
    )!,
    highlightStrength: ui.lerpDouble(
      a.highlightStrength,
      b.highlightStrength,
      t,
    )!,
    borderOpacity: ui.lerpDouble(a.borderOpacity, b.borderOpacity, t)!,
    edgeWidth: ui.lerpDouble(a.edgeWidth, b.edgeWidth, t)!,
    edgeColor: ui.Color.lerp(a.edgeColor, b.edgeColor, t)!,
    shadowStrength: ui.lerpDouble(a.shadowStrength, b.shadowStrength, t)!,
    shadowBlurSigma: ui.lerpDouble(a.shadowBlurSigma, b.shadowBlurSigma, t)!,
    shadowOffset: ui.Offset.lerp(a.shadowOffset, b.shadowOffset, t)!,
    shadowColor: ui.Color.lerp(a.shadowColor, b.shadowColor, t)!,
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
      other.edgeWidth == edgeWidth &&
      other.edgeColor == edgeColor &&
      other.shadowStrength == shadowStrength &&
      other.shadowBlurSigma == shadowBlurSigma &&
      other.shadowOffset == shadowOffset &&
      other.shadowColor == shadowColor;

  @override
  int get hashCode => Object.hashAll(<Object>[
    blurSigma,
    surfaceOpacity,
    refractionStrength,
    chromaticAberration,
    highlightStrength,
    borderOpacity,
    edgeWidth,
    edgeColor,
    shadowStrength,
    shadowBlurSigma,
    shadowOffset,
    shadowColor,
  ]);
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
