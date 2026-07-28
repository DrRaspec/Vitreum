import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_interaction.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import 'vitreum_glass.dart';

/// An accessible glass button with restrained touch, pointer, and focus
/// feedback.
class VitreumGlassButton extends StatefulWidget {
  const VitreumGlassButton({
    required this.onPressed,
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.shape = const VitreumShape.capsule(),
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.tint,
    this.semanticLabel,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final VitreumMode mode;
  final VitreumStyle style;
  final VitreumQuality quality;
  final VitreumShape shape;
  final VitreumFallbackStyle fallbackStyle;
  final Color? tint;
  final String? semanticLabel;
  final EdgeInsetsGeometry padding;

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
          onHover: widget.quality == VitreumQuality.high
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
                  : const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              scale: _pressed && !reduceMotion ? 0.975 : 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: VitreumInteractionScope(
                  data: interaction,
                  child: VitreumGlass(
                    mode: widget.mode,
                    style: widget.style,
                    quality: widget.quality,
                    shape: widget.shape,
                    tint: widget.tint,
                    interactive: true,
                    fallbackStyle: widget.fallbackStyle.copyWith(
                      highlightStrength: _pressed
                          ? (widget.fallbackStyle.highlightStrength + 0.12)
                                .clamp(0, 1)
                                .toDouble()
                          : widget.fallbackStyle.highlightStrength,
                      shadowStrength: _pressed
                          ? widget.fallbackStyle.shadowStrength * 0.76
                          : widget.fallbackStyle.shadowStrength,
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
