import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_backend_selector.dart';
import '../core/vitreum_capabilities.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_interaction.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../core/vitreum_theme.dart';
import '../platform/vitreum_method_channel.dart';
import '../rendering/flutter_glass_renderer.dart';
import '../rendering/solid_glass_renderer.dart';
import 'vitreum_glass_group.dart';
import 'vitreum_shape_clip.dart';

/// A bounded adaptive glass surface rendered behind [child].
class VitreumGlass extends StatefulWidget {
  const VitreumGlass({
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style,
    this.quality,
    this.shape = const VitreumShape.roundedRectangle(),
    this.tint,
    this.inheritTint = true,
    this.interactive = false,
    this.fallbackStyle,
    this.debugOptions = const VitreumDebugOptions(),
    this.semanticLabel,
    this.enabled = true,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Flutter content painted above the glass surface.
  final Widget child;

  /// Requested backend-selection mode.
  final VitreumMode mode;

  /// Material style, or null to inherit from [VitreumThemeData].
  final VitreumStyle? style;

  /// Simulation quality, or null to inherit from [VitreumThemeData].
  final VitreumQuality? quality;

  /// Geometry shared by the surface and child clip.
  final VitreumShape shape;

  /// Optional tint. When null, the theme tint is used if configured.
  final Color? tint;

  /// Whether a null [tint] inherits the theme tint.
  final bool inheritTint;

  /// Whether the selected renderer should enable optical interaction.
  final bool interactive;

  /// Fallback configuration, or null to inherit from [VitreumThemeData].
  final VitreumFallbackStyle? fallbackStyle;

  /// Optional diagnostic overlays and logging.
  final VitreumDebugOptions debugOptions;

  /// Optional semantic label for the surface container.
  final String? semanticLabel;

  /// When false, renders the solid backend without an effect.
  final bool enabled;

  /// How the Flutter child is clipped to [shape].
  ///
  /// The glass surface itself always remains bounded to the shape.
  final Clip clipBehavior;

  @override
  State<VitreumGlass> createState() => _VitreumGlassState();
}

class _VitreumGlassState extends State<VitreumGlass> {
  VitreumCapabilities _capabilities =
      VitreumMethodChannel.fallbackCapabilities();

  @override
  void initState() {
    super.initState();
    _loadCapabilities();
  }

  Future<void> _loadCapabilities() async {
    final result = await Vitreum.getCapabilities();
    if (mounted && result != _capabilities) {
      setState(() => _capabilities = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final grouped = VitreumGlassGroup.maybeOf(context);
    final theme = VitreumThemeData.of(context);
    final style = widget.style ?? theme.style;
    final quality = widget.quality ?? theme.quality;
    final fallbackStyle = widget.fallbackStyle ?? theme.fallbackStyle;
    final tint = widget.tint ?? (widget.inheritTint ? theme.tint : null);
    var backend = selectVitreumBackend(
      mode: widget.enabled ? widget.mode : VitreumMode.solid,
      quality: quality,
      capabilities: _capabilities,
      reduceTransparency: media?.highContrast ?? false,
    );
    // Native grouping requires one UIKit hierarchy with a
    // UIGlassContainerEffect. VitreumGlassGroup is a Flutter-only grouping
    // primitive, so grouped surfaces deliberately stay on the simulated path.
    if (backend == VitreumBackend.nativeIOS && grouped) {
      backend = selectVitreumBackend(
        mode: VitreumMode.simulated,
        quality: quality,
        capabilities: _capabilities,
        reduceTransparency: media?.highContrast ?? false,
      );
    }
    assert(() {
      if (widget.debugOptions.logBackendSelection) {
        debugPrint('Vitreum selected ${backend.name}');
      }
      return true;
    }());

    Widget result = switch (backend) {
      VitreumBackend.nativeIOS => _NativeGlass(
        shape: widget.shape,
        style: style,
        tint: tint,
        interactive: widget.interactive,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
      VitreumBackend.solid => SolidGlassRenderer(
        shape: widget.shape,
        fallbackStyle: fallbackStyle,
        tint: tint,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
      _ => FlutterGlassRenderer(
        shape: widget.shape,
        style: style,
        fallbackStyle: fallbackStyle,
        backend: backend,
        tint: tint,
        grouped: grouped,
        mergeSpacing: VitreumGlassGroup.mergeSpacingOf(context),
        interaction: VitreumInteractionScope.of(context),
        reduceMotion: media?.disableAnimations ?? false,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
    };

    if (widget.debugOptions.showBounds ||
        widget.debugOptions.showBackendLabel) {
      result = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          result,
          if (widget.debugOptions.showBounds)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _DebugBoundsPainter()),
              ),
            ),
          if (widget.debugOptions.showBackendLabel)
            Positioned(
              left: 4,
              top: 4,
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Text(
                      backend.name,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      container: widget.semanticLabel != null,
      child: result,
    );
  }
}

class _DebugBoundsPainter extends CustomPainter {
  const _DebugBoundsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.drawRect(
      (Offset.zero & size).deflate(0.75),
      Paint()
        ..color = Colors.pinkAccent
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DebugBoundsPainter oldDelegate) => false;
}

class _NativeGlass extends StatelessWidget {
  const _NativeGlass({
    required this.child,
    required this.shape,
    required this.style,
    required this.tint,
    required this.interactive,
    required this.clipBehavior,
  });

  final Widget child;
  final VitreumShape shape;
  final VitreumStyle style;
  final Color? tint;
  final bool interactive;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return child;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: IgnorePointer(
            // Flutter owns the interactive child above this platform view.
            // Native hit testing here would prevent that child receiving taps.
            ignoring: true,
            child: UiKitView(
              viewType: 'dev.vitreum/native_glass',
              creationParams: <String, Object?>{
                'shape': shape.toMap(),
                'style': style.name,
                'interactive': interactive,
                'tint': tint?.toARGB32(),
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ),
        VitreumShapeClip(
          shape: shape,
          clipBehavior: clipBehavior,
          child: child,
        ),
      ],
    );
  }
}
