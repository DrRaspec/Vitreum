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
import '../platform/vitreum_method_channel.dart';
import '../rendering/flutter_glass_renderer.dart';
import '../rendering/solid_glass_renderer.dart';
import 'vitreum_glass_group.dart';

/// A bounded adaptive glass surface rendered behind [child].
class VitreumGlass extends StatefulWidget {
  const VitreumGlass({
    required this.child,
    this.mode = VitreumMode.automatic,
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.shape = const VitreumShape.roundedRectangle(),
    this.tint,
    this.interactive = false,
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.debugOptions = const VitreumDebugOptions(),
    this.semanticLabel,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VitreumMode mode;
  final VitreumStyle style;
  final VitreumQuality quality;
  final VitreumShape shape;
  final Color? tint;
  final bool interactive;
  final VitreumFallbackStyle fallbackStyle;
  final VitreumDebugOptions debugOptions;
  final String? semanticLabel;

  /// When false, renders the solid backend without an effect.
  final bool enabled;

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
    var backend = selectVitreumBackend(
      mode: widget.enabled ? widget.mode : VitreumMode.solid,
      quality: widget.quality,
      capabilities: _capabilities,
      reduceTransparency: media?.highContrast ?? false,
    );
    // Native grouping requires one UIKit hierarchy with a
    // UIGlassContainerEffect. VitreumGlassGroup is a Flutter-only grouping
    // primitive, so grouped surfaces deliberately stay on the simulated path.
    if (backend == VitreumBackend.nativeIOS && grouped) {
      backend = selectVitreumBackend(
        mode: VitreumMode.simulated,
        quality: widget.quality,
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
        style: widget.style,
        tint: widget.tint,
        interactive: widget.interactive,
        child: widget.child,
      ),
      VitreumBackend.solid => SolidGlassRenderer(
        shape: widget.shape,
        fallbackStyle: widget.fallbackStyle,
        tint: widget.tint,
        child: widget.child,
      ),
      _ => FlutterGlassRenderer(
        shape: widget.shape,
        style: widget.style,
        fallbackStyle: widget.fallbackStyle,
        backend: backend,
        tint: widget.tint,
        grouped: grouped,
        mergeSpacing: VitreumGlassGroup.mergeSpacingOf(context),
        interaction: VitreumInteractionScope.of(context),
        reduceMotion: media?.disableAnimations ?? false,
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
  });

  final Widget child;
  final VitreumShape shape;
  final VitreumStyle style;
  final Color? tint;
  final bool interactive;

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
        child,
      ],
    );
  }
}
