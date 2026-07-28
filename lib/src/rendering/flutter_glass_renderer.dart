import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_interaction.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import 'shader/vitreum_shader_controller.dart';

/// Bounded Flutter approximation informed by Apple's documented material
/// behavior, without reproducing private Apple implementation details.
class FlutterGlassRenderer extends StatefulWidget {
  const FlutterGlassRenderer({
    required this.child,
    required this.shape,
    required this.style,
    required this.fallbackStyle,
    required this.backend,
    required this.tint,
    required this.grouped,
    required this.mergeSpacing,
    required this.interaction,
    required this.reduceMotion,
    super.key,
  });

  final Widget child;
  final VitreumShape shape;
  final VitreumStyle style;
  final VitreumFallbackStyle fallbackStyle;
  final VitreumBackend backend;
  final Color? tint;
  final bool grouped;
  final double mergeSpacing;
  final VitreumInteractionData interaction;
  final bool reduceMotion;

  @override
  State<FlutterGlassRenderer> createState() => _FlutterGlassRendererState();
}

class _FlutterGlassRendererState extends State<FlutterGlassRenderer> {
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    _loadShaderIfNeeded();
  }

  @override
  void didUpdateWidget(FlutterGlassRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backend != widget.backend) _loadShaderIfNeeded();
  }

  Future<void> _loadShaderIfNeeded() async {
    if (widget.backend != VitreumBackend.flutterHigh || _shader != null) return;
    final program = await VitreumShaderController.instance.load();
    if (program == null || !mounted) return;
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.fallbackStyle.validated();
    final filter = _createFilter(values);
    final base = widget.tint ?? Colors.white;
    final isClear = widget.style == VitreumStyle.clear;
    final opacity = values.surfaceOpacity * (isClear ? 0.34 : 0.72);

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(
            constraints.hasBoundedWidth ? constraints.maxWidth : 0,
            constraints.hasBoundedHeight ? constraints.maxHeight : 0,
          );
          final filteredSurface = widget.grouped && _shader == null
              ? BackdropFilter.grouped(
                  filter: filter,
                  child: _surface(context, base, opacity, values, size),
                )
              : BackdropFilter(
                  filter: filter,
                  child: _surface(context, base, opacity, values, size),
                );

          return CustomPaint(
            painter: _AmbientShadowPainter(
              shape: widget.shape,
              strength: values.shadowStrength,
              mergeSpacing: widget.backend == VitreumBackend.flutterLow
                  ? 0
                  : widget.mergeSpacing,
            ),
            child: ClipPath(
              clipper: _GlassShapeClipper(widget.shape),
              child: filteredSurface,
            ),
          );
        },
      ),
    );
  }

  ui.ImageFilter _createFilter(VitreumFallbackStyle values) {
    final shader = _shader;
    if (shader != null &&
        widget.backend == VitreumBackend.flutterHigh &&
        ui.ImageFilter.isShaderFilterSupported) {
      // 0–1 are supplied by the engine as u_size.
      shader.setFloat(
        2,
        values.refractionStrength * (widget.interaction.pressed ? 1.12 : 1),
      );
      shader.setFloat(3, values.chromaticAberration);
      shader.setFloat(4, values.blurSigma.clamp(0, 18) * 0.38);
      try {
        return ui.ImageFilter.shader(shader);
      } on Object {
        // Unsupported renderers retain the bounded blur path below.
      }
    }

    final sigma = widget.backend == VitreumBackend.flutterLow
        ? values.blurSigma.clamp(0, 8).toDouble()
        : values.blurSigma.clamp(0, 16).toDouble();
    return ui.ImageFilter.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      tileMode: TileMode.clamp,
    );
  }

  Widget _surface(
    BuildContext context,
    Color base,
    double opacity,
    VitreumFallbackStyle values,
    Size size,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final separationColor = dark ? Colors.white : Colors.black;
    final targetInteraction = widget.backend == VitreumBackend.flutterLow
        ? 0.0
        : widget.interaction.intensity;
    return TweenAnimationBuilder<double>(
      duration: widget.reduceMotion
          ? Duration.zero
          : Duration(milliseconds: widget.interaction.pressed ? 75 : 160),
      curve: widget.interaction.pressed
          ? Curves.easeOutCubic
          : Curves.easeInOutCubic,
      tween: Tween<double>(end: targetInteraction),
      child: widget.child,
      builder: (context, interactionIntensity, child) => Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Positioned.fill(
            child: ColoredBox(color: base.withValues(alpha: opacity)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(-0.9, -1),
                  end: const Alignment(0.8, 1),
                  stops: const <double>[0, 0.24, 0.62, 1],
                  colors: <Color>[
                    Colors.white.withValues(
                      alpha: values.highlightStrength * 0.30,
                    ),
                    Colors.white.withValues(alpha: 0.015),
                    base.withValues(alpha: opacity * 0.18),
                    separationColor.withValues(alpha: dark ? 0.035 : 0.025),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _InteractionLightPainter(
                  position: widget.interaction.position,
                  intensity: interactionIntensity,
                  color: base,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _EdgeLightingPainter(
                  shape: widget.shape,
                  strength: values.borderOpacity + interactionIntensity * 0.06,
                  lightBackground: !dark,
                ),
              ),
            ),
          ),
          child!,
        ],
      ),
    );
  }
}

Path _shapePath(Size size, VitreumShape shape, [double inset = 0]) {
  final rect = (Offset.zero & size).deflate(inset);
  return switch (shape.kind) {
    VitreumShapeKind.roundedRectangle =>
      Path()..addRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(
            (shape.radius - inset).clamp(0, rect.shortestSide / 2),
          ),
        ),
      ),
    VitreumShapeKind.capsule =>
      Path()..addRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2)),
      ),
    VitreumShapeKind.circle =>
      Path()..addOval(
        Rect.fromCircle(center: rect.center, radius: rect.shortestSide / 2),
      ),
  };
}

class _GlassShapeClipper extends CustomClipper<Path> {
  const _GlassShapeClipper(this.shape);

  final VitreumShape shape;

  @override
  Path getClip(Size size) => _shapePath(size, shape);

  @override
  bool shouldReclip(_GlassShapeClipper oldClipper) => oldClipper.shape != shape;
}

class _EdgeLightingPainter extends CustomPainter {
  const _EdgeLightingPainter({
    required this.shape,
    required this.strength,
    required this.lightBackground,
  });

  final VitreumShape shape;
  final double strength;
  final bool lightBackground;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || strength <= 0) return;
    final rect = Offset.zero & size;
    // A sweep lets each corner carry a different edge weight. Keeping this
    // contextual white in soft-light mode makes it borrow colour from the
    // sampled backdrop instead of reading as a permanent white/cyan stroke.
    // Light themes reduce the complete treatment further.
    final effectiveStrength = strength * (lightBackground ? 0.46 : 1);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..blendMode = BlendMode.softLight
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: <Color>[
          Colors.white.withValues(alpha: effectiveStrength * 0.285),
          Colors.white.withValues(alpha: effectiveStrength * 0.14),
          Colors.white.withValues(alpha: effectiveStrength * 0.29),
          Colors.white.withValues(alpha: effectiveStrength * 0.72),
          Colors.white.withValues(alpha: effectiveStrength * 0.43),
          Colors.white.withValues(alpha: effectiveStrength * 0.285),
        ],
        stops: const <double>[0, 0.125, 0.375, 0.625, 0.875, 1],
      ).createShader(rect);
    canvas.drawPath(_shapePath(size, shape, 0.8), paint);
  }

  @override
  bool shouldRepaint(_EdgeLightingPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.strength != strength ||
      oldDelegate.lightBackground != lightBackground;
}

class _AmbientShadowPainter extends CustomPainter {
  const _AmbientShadowPainter({
    required this.shape,
    required this.strength,
    required this.mergeSpacing,
  });

  final VitreumShape shape;
  final double strength;
  final double mergeSpacing;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || strength <= 0) return;
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(
      _shapePath(size, shape, 1.5),
      Paint()
        ..color = Colors.black.withValues(alpha: strength * 0.34)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    if (mergeSpacing > 0) {
      canvas.drawPath(
        _shapePath(size, shape, 0.5),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.018)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            mergeSpacing.clamp(2, 18) * 0.5,
          ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmbientShadowPainter oldDelegate) =>
      oldDelegate.shape != shape ||
      oldDelegate.strength != strength ||
      oldDelegate.mergeSpacing != mergeSpacing;
}

class _InteractionLightPainter extends CustomPainter {
  const _InteractionLightPainter({
    required this.position,
    required this.intensity,
    required this.color,
  });

  final Offset? position;
  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;
    final origin = position ?? size.center(Offset.zero);
    final radius = size.longestSide * (0.28 + intensity * 0.22);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..blendMode = BlendMode.screen
        ..shader = RadialGradient(
          colors: <Color>[
            Color.lerp(
              Colors.white,
              color,
              0.18,
            )!.withValues(alpha: 0.16 * intensity),
            Colors.white.withValues(alpha: 0.045 * intensity),
            Colors.transparent,
          ],
          stops: const <double>[0, 0.48, 1],
        ).createShader(Rect.fromCircle(center: origin, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(_InteractionLightPainter oldDelegate) =>
      oldDelegate.position != position ||
      oldDelegate.intensity != intensity ||
      oldDelegate.color != color;
}
