import 'package:flutter/material.dart';

import 'vitreum_config.dart';
import 'vitreum_interaction_style.dart';
import 'vitreum_navigation_bar_style.dart';
import 'vitreum_quality.dart';
import 'vitreum_style.dart';

/// Package-wide Vitreum defaults.
///
/// Install this through [ThemeData.extensions] in Material applications or
/// use [VitreumTheme] in Cupertino and other widget trees.
@immutable
class VitreumThemeData extends ThemeExtension<VitreumThemeData> {
  const VitreumThemeData({
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.tint,
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.interactionStyle = const VitreumInteractionStyle(),
    this.navigationBarStyle = const VitreumNavigationBarStyle(),
  });

  /// Default material style for surfaces that omit `style`.
  final VitreumStyle style;

  /// Default simulation quality for surfaces that omit `quality`.
  final VitreumQuality quality;

  /// Optional default tint. A per-widget tint takes precedence.
  final Color? tint;

  /// Default configuration for simulated and solid fallbacks.
  final VitreumFallbackStyle fallbackStyle;

  /// Default feedback configuration for interactive controls.
  final VitreumInteractionStyle interactionStyle;

  /// Default appearance for Flutter-owned navigation bars.
  final VitreumNavigationBarStyle navigationBarStyle;

  /// Returns the nearest Vitreum theme or the package defaults.
  static VitreumThemeData of(BuildContext context) =>
      VitreumTheme.maybeOf(context) ??
      Theme.of(context).extension<VitreumThemeData>() ??
      const VitreumThemeData();

  @override
  VitreumThemeData copyWith({
    VitreumStyle? style,
    VitreumQuality? quality,
    Color? tint,
    VitreumFallbackStyle? fallbackStyle,
    VitreumInteractionStyle? interactionStyle,
    VitreumNavigationBarStyle? navigationBarStyle,
    bool clearTint = false,
  }) => VitreumThemeData(
    style: style ?? this.style,
    quality: quality ?? this.quality,
    tint: clearTint ? null : tint ?? this.tint,
    fallbackStyle: fallbackStyle ?? this.fallbackStyle,
    interactionStyle: interactionStyle ?? this.interactionStyle,
    navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
  );

  @override
  VitreumThemeData lerp(covariant VitreumThemeData? other, double t) {
    if (other == null) return this;
    return VitreumThemeData(
      style: t < 0.5 ? style : other.style,
      quality: t < 0.5 ? quality : other.quality,
      tint: Color.lerp(tint, other.tint, t),
      fallbackStyle: VitreumFallbackStyle.lerp(
        fallbackStyle,
        other.fallbackStyle,
        t,
      ),
      interactionStyle: VitreumInteractionStyle.lerp(
        interactionStyle,
        other.interactionStyle,
        t,
      ),
      navigationBarStyle: VitreumNavigationBarStyle.lerp(
        navigationBarStyle,
        other.navigationBarStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VitreumThemeData &&
      other.style == style &&
      other.quality == quality &&
      other.tint == tint &&
      other.fallbackStyle == fallbackStyle &&
      other.interactionStyle == interactionStyle &&
      other.navigationBarStyle == navigationBarStyle;

  @override
  int get hashCode => Object.hash(
    style,
    quality,
    tint,
    fallbackStyle,
    interactionStyle,
    navigationBarStyle,
  );
}

/// Supplies [VitreumThemeData] to any Flutter widget subtree.
///
/// This wrapper is especially useful with `CupertinoApp`, which does not use
/// Material [ThemeData.extensions]. A nearer [VitreumTheme] takes precedence
/// over a Material theme extension.
class VitreumTheme extends InheritedTheme {
  const VitreumTheme({required this.data, required super.child, super.key});

  /// Defaults available to descendant Vitreum widgets.
  final VitreumThemeData data;

  /// Returns the nearest inherited Vitreum theme, if one exists.
  static VitreumThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VitreumTheme>()?.data;

  @override
  bool updateShouldNotify(VitreumTheme oldWidget) => data != oldWidget.data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      VitreumTheme(data: data, child: child);
}
