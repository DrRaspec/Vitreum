import 'package:flutter/foundation.dart';

import 'vitreum_backend.dart';
import 'vitreum_capabilities.dart';
import 'vitreum_quality.dart';

/// Pure backend selection used by widgets and unit tests.
VitreumBackend selectVitreumBackend({
  required VitreumMode mode,
  required VitreumQuality quality,
  required VitreumCapabilities capabilities,
  required bool reduceTransparency,
}) {
  if (mode == VitreumMode.solid ||
      reduceTransparency ||
      capabilities.reducedTransparency) {
    return VitreumBackend.solid;
  }

  final nativeAvailable =
      capabilities.platform == VitreumPlatform.ios &&
      capabilities.nativeApiExists &&
      capabilities.nativeViewCanBeCreated &&
      capabilities.nativeBackdropCompositionValidated;

  if ((mode == VitreumMode.native || mode == VitreumMode.automatic) &&
      nativeAvailable) {
    return VitreumBackend.nativeIOS;
  }

  if (!capabilities.simulatedRendererAvailable) {
    return VitreumBackend.solid;
  }

  return switch (quality) {
    VitreumQuality.low => VitreumBackend.flutterLow,
    VitreumQuality.high when capabilities.shaderAvailable =>
      VitreumBackend.flutterHigh,
    VitreumQuality.high ||
    VitreumQuality.balanced ||
    VitreumQuality.adaptive => VitreumBackend.flutterBalanced,
  };
}

@visibleForTesting
VitreumBackend debugSelectVitreumBackend({
  required VitreumMode mode,
  required VitreumQuality quality,
  required VitreumCapabilities capabilities,
  bool reduceTransparency = false,
}) => selectVitreumBackend(
  mode: mode,
  quality: quality,
  capabilities: capabilities,
  reduceTransparency: reduceTransparency,
);
