import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Motion and feedback used by interactive Vitreum controls.
@immutable
class VitreumInteractionStyle {
  const VitreumInteractionStyle({
    this.pressedScale = 0.975,
    this.duration = const Duration(milliseconds: 120),
    this.curve = Curves.easeOutCubic,
    this.pressedHighlightBoost = 0.12,
    this.pressedShadowFactor = 0.76,
    this.minimumSize = const Size.square(48),
  });

  /// Scale applied while the control is pressed.
  final double pressedScale;

  /// Duration of the press and release scale animation.
  final Duration duration;

  /// Curve used by the press and release scale animation.
  final Curve curve;

  /// Highlight-strength increase applied while pressed.
  final double pressedHighlightBoost;

  /// Multiplier applied to the ambient shadow while pressed.
  final double pressedShadowFactor;

  /// Minimum interactive target size.
  final Size minimumSize;

  /// Returns values clamped to safe layout and rendering ranges.
  VitreumInteractionStyle validated() => VitreumInteractionStyle(
    pressedScale: _finiteClamp(pressedScale, 0.8, 1.2, 0.975),
    duration: duration.isNegative || duration > const Duration(seconds: 2)
        ? const Duration(milliseconds: 120)
        : duration,
    curve: curve,
    pressedHighlightBoost: _finiteClamp(pressedHighlightBoost, 0, 1, 0.12),
    pressedShadowFactor: _finiteClamp(pressedShadowFactor, 0, 1, 0.76),
    minimumSize: Size(
      _finiteClamp(minimumSize.width, 0, 400, 48),
      _finiteClamp(minimumSize.height, 0, 400, 48),
    ),
  );

  /// Returns a copy with the supplied values replaced.
  VitreumInteractionStyle copyWith({
    double? pressedScale,
    Duration? duration,
    Curve? curve,
    double? pressedHighlightBoost,
    double? pressedShadowFactor,
    Size? minimumSize,
  }) => VitreumInteractionStyle(
    pressedScale: pressedScale ?? this.pressedScale,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    pressedHighlightBoost: pressedHighlightBoost ?? this.pressedHighlightBoost,
    pressedShadowFactor: pressedShadowFactor ?? this.pressedShadowFactor,
    minimumSize: minimumSize ?? this.minimumSize,
  );

  /// Interpolates between two interaction styles.
  static VitreumInteractionStyle lerp(
    VitreumInteractionStyle a,
    VitreumInteractionStyle b,
    double t,
  ) => VitreumInteractionStyle(
    pressedScale: lerpDouble(a.pressedScale, b.pressedScale, t)!,
    duration: Duration(
      microseconds: lerpDouble(
        a.duration.inMicroseconds,
        b.duration.inMicroseconds,
        t,
      )!.round(),
    ),
    curve: t < 0.5 ? a.curve : b.curve,
    pressedHighlightBoost: lerpDouble(
      a.pressedHighlightBoost,
      b.pressedHighlightBoost,
      t,
    )!,
    pressedShadowFactor: lerpDouble(
      a.pressedShadowFactor,
      b.pressedShadowFactor,
      t,
    )!,
    minimumSize: Size.lerp(a.minimumSize, b.minimumSize, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is VitreumInteractionStyle &&
      other.pressedScale == pressedScale &&
      other.duration == duration &&
      other.curve == curve &&
      other.pressedHighlightBoost == pressedHighlightBoost &&
      other.pressedShadowFactor == pressedShadowFactor &&
      other.minimumSize == minimumSize;

  @override
  int get hashCode => Object.hash(
    pressedScale,
    duration,
    curve,
    pressedHighlightBoost,
    pressedShadowFactor,
    minimumSize,
  );
}

double _finiteClamp(double value, double min, double max, double fallback) =>
    value.isFinite ? value.clamp(min, max) : fallback;
