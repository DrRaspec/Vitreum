import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_config.dart';
import '../core/vitreum_quality.dart';
import '../core/vitreum_shape.dart';
import '../core/vitreum_style.dart';
import '../platform/vitreum_method_channel.dart';
import 'vitreum_glass.dart';

/// A deliberately specialized, bounded native iOS glass overlay.
///
/// The validated topology is one platform-view overlay above Flutter content.
/// Do not use several instances on the same route: multiple independent native
/// glass platform views have not passed Vitreum's composition diagnostic.
/// Unsupported and unvalidated environments use the Flutter simulation.
class VitreumNativeGlassOverlay extends StatefulWidget {
  const VitreumNativeGlassOverlay({
    required this.child,
    this.style = VitreumStyle.regular,
    this.quality = VitreumQuality.adaptive,
    this.shape = const VitreumShape.roundedRectangle(),
    this.tint,
    this.interactive = false,
    this.fallbackStyle = const VitreumFallbackStyle(),
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VitreumStyle style;
  final VitreumQuality quality;
  final VitreumShape shape;
  final Color? tint;
  final bool interactive;
  final VitreumFallbackStyle fallbackStyle;
  final String? semanticLabel;

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
        style: widget.style,
        quality: widget.quality,
        shape: widget.shape,
        tint: widget.tint,
        interactive: widget.interactive,
        fallbackStyle: widget.fallbackStyle,
        semanticLabel: widget.semanticLabel,
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
                  'style': widget.style.name,
                  'interactive': widget.interactive,
                  'tint': widget.tint?.toARGB32(),
                },
                creationParamsCodec: const StandardMessageCodec(),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
