import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_interaction.dart';
import '../core/vitreum_interaction_style.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../core/vitreum_theme.dart';
import 'vitreum_glass.dart';

/// An accessible glass button with restrained touch, pointer, and focus
/// feedback.
class VitreumGlassButton extends StatefulWidget {
  const VitreumGlassButton({
    required this.onPressed,
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style,
    this.quality,
    this.shape = const VitreumShape.capsule(),
    this.fallbackStyle,
    this.tint,
    this.inheritTint = true,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.interactionStyle,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Called when activated. A null callback disables the button.
  final VoidCallback? onPressed;

  /// Button content.
  final Widget child;

  /// Requested backend-selection mode.
  final VitreumMode mode;

  /// Material style, or null to inherit from [VitreumThemeData].
  final VitreumStyle? style;

  /// Simulation quality, or null to inherit from [VitreumThemeData].
  final VitreumQuality? quality;

  /// Button surface and clipping geometry.
  final VitreumShape shape;

  /// Fallback configuration, or null to inherit from [VitreumThemeData].
  final VitreumFallbackStyle? fallbackStyle;

  /// Optional tint, with theme fallback.
  final Color? tint;

  /// Whether a null [tint] inherits the theme tint.
  final bool inheritTint;

  /// Optional accessibility label.
  final String? semanticLabel;

  /// Empty space around [child].
  final EdgeInsetsGeometry padding;

  /// Feedback configuration, or null to inherit from [VitreumThemeData].
  final VitreumInteractionStyle? interactionStyle;

  /// How the Flutter child is clipped to [shape].
  final Clip clipBehavior;

  @override
  State<VitreumGlassButton> createState() => _VitreumGlassButtonState();
}

class _VitreumGlassButtonState extends State<VitreumGlassButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;
  Offset? _interactionPosition;

  void _setPressed(bool value, [Offset? position]) {
    if (_pressed == value && position == null) return;
    setState(() {
      _pressed = value;
      if (position != null) _interactionPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final theme = VitreumThemeData.of(context);
    final style = widget.style ?? theme.style;
    final quality = widget.quality ?? theme.quality;
    final fallbackStyle = widget.fallbackStyle ?? theme.fallbackStyle;
    final interactionStyle = widget.interactionStyle ?? theme.interactionStyle;
    final interactionValues = interactionStyle.validated();
    final enabled = widget.onPressed != null;
    final interaction = VitreumInteractionData(
      pressed: _pressed,
      hovered: _hovered,
      focused: _focused,
      position: _interactionPosition,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: MouseRegion(
          onHover: quality == VitreumQuality.high
              ? (event) =>
                    setState(() => _interactionPosition = event.localPosition)
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onTapDown: enabled
                ? (details) => _setPressed(true, details.localPosition)
                : null,
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            child: AnimatedScale(
              duration: reduceMotion
                  ? Duration.zero
                  : interactionValues.duration,
              curve: interactionValues.curve,
              scale: _pressed && !reduceMotion
                  ? interactionValues.pressedScale
                  : 1,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: interactionValues.minimumSize.width,
                  minHeight: interactionValues.minimumSize.height,
                ),
                child: VitreumInteractionScope(
                  data: interaction,
                  child: VitreumGlass(
                    mode: widget.mode,
                    style: style,
                    quality: quality,
                    shape: widget.shape,
                    tint:
                        widget.tint ?? (widget.inheritTint ? theme.tint : null),
                    inheritTint: false,
                    interactive: true,
                    clipBehavior: widget.clipBehavior,
                    fallbackStyle: fallbackStyle.copyWith(
                      highlightStrength: _pressed
                          ? (fallbackStyle.highlightStrength +
                                    interactionValues.pressedHighlightBoost)
                                .clamp(0, 1)
                                .toDouble()
                          : fallbackStyle.highlightStrength,
                      shadowStrength: _pressed
                          ? fallbackStyle.shadowStrength *
                                interactionValues.pressedShadowFactor
                          : fallbackStyle.shadowStrength,
                    ),
                    child: Padding(
                      padding: widget.padding,
                      child: Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
