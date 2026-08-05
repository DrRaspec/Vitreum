import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../core/vitreum_theme.dart';
import '../platform/vitreum_method_channel.dart';
import 'vitreum_glass.dart';
import 'vitreum_shape_clip.dart';

/// A deliberately specialized, bounded native iOS glass overlay.
///
/// The validated topology is one platform-view overlay above Flutter content.
/// Do not use several instances on the same route: multiple independent native
/// glass platform views have not passed Vitreum's composition diagnostic.
/// Unsupported and unvalidated environments use the Flutter simulation.
class VitreumNativeGlassOverlay extends StatefulWidget {
  const VitreumNativeGlassOverlay({
    required this.child,
    this.style,
    this.quality,
    this.shape = const VitreumShape.roundedRectangle(),
    this.tint,
    this.inheritTint = true,
    this.interactive = false,
    this.fallbackStyle,
    this.semanticLabel,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Flutter content painted above the native or simulated glass.
  final Widget child;

  /// Material style, or null to inherit from [VitreumThemeData].
  final VitreumStyle? style;

  /// Simulation quality used after fallback, or null to inherit.
  final VitreumQuality? quality;

  /// Geometry shared by the native surface and Flutter child clip.
  final VitreumShape shape;

  /// Optional native or simulated tint, with theme fallback.
  final Color? tint;

  /// Whether a null [tint] inherits the theme tint.
  final bool inheritTint;

  /// Whether supported native and simulated interaction is enabled.
  final bool interactive;

  /// Simulated fallback configuration, or null to inherit.
  final VitreumFallbackStyle? fallbackStyle;

  /// Optional semantic label for the surface container.
  final String? semanticLabel;

  /// How the Flutter child is clipped to [shape].
  final Clip clipBehavior;

  @override
  State<VitreumNativeGlassOverlay> createState() =>
      _VitreumNativeGlassOverlayState();
}

class _VitreumNativeGlassOverlayState extends State<VitreumNativeGlassOverlay> {
  var _capabilities = VitreumMethodChannel.fallbackCapabilities();

  @override
  void initState() {
    super.initState();
    Vitreum.getCapabilities().then((value) {
      if (mounted && value != _capabilities) {
        setState(() => _capabilities = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = VitreumThemeData.of(context);
    final style = widget.style ?? theme.style;
    final quality = widget.quality ?? theme.quality;
    final fallbackStyle = widget.fallbackStyle ?? theme.fallbackStyle;
    final tint = widget.tint ?? (widget.inheritTint ? theme.tint : null);
    final useNative =
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        _capabilities.nativeApiExists &&
        _capabilities.nativeViewCanBeCreated &&
        _capabilities.nativeSingleOverlayCompositionValidated &&
        !_capabilities.reducedTransparency &&
        !MediaQuery.highContrastOf(context);

    if (!useNative) {
      return VitreumGlass(
        mode: VitreumMode.simulated,
        style: style,
        quality: quality,
        shape: widget.shape,
        tint: tint,
        inheritTint: false,
        interactive: widget.interactive,
        fallbackStyle: fallbackStyle,
        semanticLabel: widget.semanticLabel,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      );
    }

    return Semantics(
      label: widget.semanticLabel,
      container: widget.semanticLabel != null,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: UiKitView(
                viewType: 'dev.vitreum/native_glass',
                creationParams: <String, Object?>{
                  'shape': widget.shape.toMap(),
                  'style': style.name,
                  'interactive': widget.interactive,
                  'tint': tint?.toARGB32(),
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          ),
          VitreumShapeClip(
            shape: widget.shape,
            clipBehavior: widget.clipBehavior,
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
