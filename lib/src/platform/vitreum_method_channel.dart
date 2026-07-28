import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/vitreum_backend.dart';
import '../core/vitreum_capabilities.dart';
import '../core/vitreum_config.dart';

/// Method-channel capability provider.
class VitreumMethodChannel implements VitreumPlatformInterface {
  const VitreumMethodChannel();

  static const MethodChannel _channel = MethodChannel(
    'dev.vitreum/capabilities',
  );

  static VitreumPlatform currentPlatform() {
    if (kIsWeb) return VitreumPlatform.other;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => VitreumPlatform.ios,
      TargetPlatform.android => VitreumPlatform.android,
      _ => VitreumPlatform.other,
    };
  }

  /// Safe capabilities used when native registration is absent.
  static VitreumCapabilities fallbackCapabilities() {
    final platform = currentPlatform();
    return VitreumCapabilities(
      platform: platform,
      nativeApiExists: false,
      nativeViewCanBeCreated: false,
      nativeBackdropCompositionValidated: false,
      nativeSingleOverlayCompositionValidated: false,
      nativeInteractiveEffectAvailable: false,
      simulatedRendererAvailable: platform != VitreumPlatform.other,
      shaderAvailable: false,
      reducedTransparency: false,
      selectedAutomaticBackend: platform == VitreumPlatform.other
          ? VitreumBackend.solid
          : VitreumBackend.flutterBalanced,
    );
  }

  @override
  Future<VitreumCapabilities> getCapabilities() async {
    final response = await _channel.invokeMapMethod<Object?, Object?>(
      'getCapabilities',
    );
    if (response == null) return fallbackCapabilities();
    return VitreumCapabilities.fromMap(
      response,
      fallbackPlatform: currentPlatform(),
    );
  }
}
