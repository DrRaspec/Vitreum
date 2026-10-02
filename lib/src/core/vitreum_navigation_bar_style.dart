import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Layout and color treatment for Vitreum's Flutter-owned navigation bars.
@immutable
class VitreumNavigationBarStyle {
  const VitreumNavigationBarStyle({
    this.height = 64,
    this.horizontalPadding = 8,
    this.destinationMinWidth = 88,
    this.destinationMinHeight = 44,
    this.indicatorSize = 36,
    this.iconSize = 24,
    this.itemSpacing = 6,
    this.labelFontSize = 13,
    this.selectedColor = const Color(0xF0FFFFFF),
    this.unselectedColor = const Color(0x94FFFFFF),
    this.indicatorColor = const Color(0x0DFFFFFF),
    this.pressedIndicatorColor = const Color(0x1AFFFFFF),
  });

  /// Total bar content height.
  final double height;

  /// Empty horizontal space inside the glass surface.
  final double horizontalPadding;

  /// Minimum width of each navigation destination.
  final double destinationMinWidth;

  /// Minimum height of each navigation destination.
  final double destinationMinHeight;

  /// Width and height of the circular selection indicator.
  final double indicatorSize;

  /// Navigation icon size.
  final double iconSize;

  /// Horizontal space between each icon and label.
  final double itemSpacing;

  /// Destination label font size.
  final double labelFontSize;

  /// Foreground color for the selected destination.
  final Color selectedColor;

  /// Foreground color for unselected destinations.
  final Color unselectedColor;

  /// Indicator color for the selected destination.
  final Color indicatorColor;

  /// Indicator color while a destination is pressed.
  final Color pressedIndicatorColor;

  /// Returns values clamped to safe layout ranges.
  VitreumNavigationBarStyle validated() => VitreumNavigationBarStyle(
    height: _finiteClamp(height, 0, 400, 64),
    horizontalPadding: _finiteClamp(horizontalPadding, 0, 100, 8),
    destinationMinWidth: _finiteClamp(destinationMinWidth, 0, 400, 88),
    destinationMinHeight: _finiteClamp(destinationMinHeight, 0, 400, 44),
    indicatorSize: _finiteClamp(indicatorSize, 0, 200, 36),
    iconSize: _finiteClamp(iconSize, 0, 200, 24),
    itemSpacing: _finiteClamp(itemSpacing, 0, 100, 6),
    labelFontSize: _finiteClamp(labelFontSize, 0, 100, 13),
    selectedColor: selectedColor,
    unselectedColor: unselectedColor,
    indicatorColor: indicatorColor,
    pressedIndicatorColor: pressedIndicatorColor,
  );

  /// Returns a copy with the supplied values replaced.
  VitreumNavigationBarStyle copyWith({
    double? height,
    double? horizontalPadding,
    double? destinationMinWidth,
    double? destinationMinHeight,
    double? indicatorSize,
    double? iconSize,
    double? itemSpacing,
    double? labelFontSize,
    Color? selectedColor,
    Color? unselectedColor,
    Color? indicatorColor,
    Color? pressedIndicatorColor,
  }) => VitreumNavigationBarStyle(
    height: height ?? this.height,
    horizontalPadding: horizontalPadding ?? this.horizontalPadding,
    destinationMinWidth: destinationMinWidth ?? this.destinationMinWidth,
    destinationMinHeight: destinationMinHeight ?? this.destinationMinHeight,
    indicatorSize: indicatorSize ?? this.indicatorSize,
    iconSize: iconSize ?? this.iconSize,
    itemSpacing: itemSpacing ?? this.itemSpacing,
    labelFontSize: labelFontSize ?? this.labelFontSize,
    selectedColor: selectedColor ?? this.selectedColor,
    unselectedColor: unselectedColor ?? this.unselectedColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    pressedIndicatorColor: pressedIndicatorColor ?? this.pressedIndicatorColor,
  );

  /// Interpolates between two navigation styles.
  static VitreumNavigationBarStyle lerp(
    VitreumNavigationBarStyle a,
    VitreumNavigationBarStyle b,
    double t,
  ) => VitreumNavigationBarStyle(
    height: lerpDouble(a.height, b.height, t)!,
    horizontalPadding: lerpDouble(a.horizontalPadding, b.horizontalPadding, t)!,
    destinationMinWidth: lerpDouble(
      a.destinationMinWidth,
      b.destinationMinWidth,
      t,
    )!,
    destinationMinHeight: lerpDouble(
      a.destinationMinHeight,
      b.destinationMinHeight,
      t,
    )!,
    indicatorSize: lerpDouble(a.indicatorSize, b.indicatorSize, t)!,
    iconSize: lerpDouble(a.iconSize, b.iconSize, t)!,
    itemSpacing: lerpDouble(a.itemSpacing, b.itemSpacing, t)!,
    labelFontSize: lerpDouble(a.labelFontSize, b.labelFontSize, t)!,
    selectedColor: Color.lerp(a.selectedColor, b.selectedColor, t)!,
    unselectedColor: Color.lerp(a.unselectedColor, b.unselectedColor, t)!,
    indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t)!,
    pressedIndicatorColor: Color.lerp(
      a.pressedIndicatorColor,
      b.pressedIndicatorColor,
      t,
    )!,
  );

  @override
  bool operator ==(Object other) =>
      other is VitreumNavigationBarStyle &&
      other.height == height &&
      other.horizontalPadding == horizontalPadding &&
      other.destinationMinWidth == destinationMinWidth &&
      other.destinationMinHeight == destinationMinHeight &&
      other.indicatorSize == indicatorSize &&
      other.iconSize == iconSize &&
      other.itemSpacing == itemSpacing &&
      other.labelFontSize == labelFontSize &&
      other.selectedColor == selectedColor &&
      other.unselectedColor == unselectedColor &&
      other.indicatorColor == indicatorColor &&
      other.pressedIndicatorColor == pressedIndicatorColor;

  @override
  int get hashCode => Object.hashAll(<Object>[
    height,
    horizontalPadding,
    destinationMinWidth,
    destinationMinHeight,
    indicatorSize,
    iconSize,
    itemSpacing,
    labelFontSize,
    selectedColor,
    unselectedColor,
    indicatorColor,
    pressedIndicatorColor,
  ]);
}

double _finiteClamp(double value, double min, double max, double fallback) =>
    value.isFinite ? value.clamp(min, max) : fallback;
