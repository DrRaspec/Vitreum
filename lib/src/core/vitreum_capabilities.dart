import 'package:flutter/foundation.dart';

import 'vitreum_backend.dart';

/// A snapshot of runtime Vitreum support.
@immutable
class VitreumCapabilities {
  /// Creates a capability snapshot.
  const VitreumCapabilities({
    required this.platform,
    required this.nativeApiExists,
    required this.nativeViewCanBeCreated,
    required this.nativeBackdropCompositionValidated,
    required this.nativeSingleOverlayCompositionValidated,
    required this.nativeInteractiveEffectAvailable,
    required this.simulatedRendererAvailable,
    required this.shaderAvailable,
    required this.reducedTransparency,
    required this.selectedAutomaticBackend,
    this.osVersion,
  });

  /// Parses a platform-channel response.
  factory VitreumCapabilities.fromMap(
    Map<Object?, Object?> map, {
    required VitreumPlatform fallbackPlatform,
  }) {
    final platformName = map['platform'];
    final platform = VitreumPlatform.values
        .where((value) => value.name == platformName)
        .firstOrNull;
    final backendName = map['selectedAutomaticBackend'];
    final backend = VitreumBackend.values
        .where((value) => value.name == backendName)
        .firstOrNull;
    return VitreumCapabilities(
      platform: platform ?? fallbackPlatform,
      nativeApiExists:
          map['nativeApiExists'] == true ||
          map['nativeGlassApiAvailable'] == true,
      nativeViewCanBeCreated:
          map['nativeViewCanBeCreated'] == true ||
          map['nativeBackendAvailable'] == true,
      nativeBackdropCompositionValidated:
          map['nativeBackdropCompositionValidated'] == true,
      nativeSingleOverlayCompositionValidated:
          map['nativeSingleOverlayCompositionValidated'] == true,
      nativeInteractiveEffectAvailable:
          map['nativeInteractiveEffectAvailable'] == true,
      simulatedRendererAvailable:
          map['simulatedRendererAvailable'] != false &&
          map['simulatedBackendAvailable'] != false,
      shaderAvailable: map['shaderAvailable'] == true,
      reducedTransparency: map['reducedTransparency'] == true,
      selectedAutomaticBackend: backend ?? VitreumBackend.flutterBalanced,
      osVersion: map['osVersion'] as String?,
    );
  }

  final VitreumPlatform platform;
  final bool nativeApiExists;
  final bool nativeViewCanBeCreated;
  final bool nativeBackdropCompositionValidated;
  final bool nativeSingleOverlayCompositionValidated;
  final bool nativeInteractiveEffectAvailable;
  final bool simulatedRendererAvailable;
  final bool shaderAvailable;
  final bool reducedTransparency;
  final VitreumBackend selectedAutomaticBackend;
  final String? osVersion;

  /// Returns a modified copy.
  VitreumCapabilities copyWith({
    VitreumPlatform? platform,
    bool? nativeApiExists,
    bool? nativeViewCanBeCreated,
    bool? nativeBackdropCompositionValidated,
    bool? nativeSingleOverlayCompositionValidated,
    bool? nativeInteractiveEffectAvailable,
    bool? simulatedRendererAvailable,
    bool? shaderAvailable,
    bool? reducedTransparency,
    VitreumBackend? selectedAutomaticBackend,
    String? osVersion,
  }) => VitreumCapabilities(
    platform: platform ?? this.platform,
    nativeApiExists: nativeApiExists ?? this.nativeApiExists,
    nativeViewCanBeCreated:
        nativeViewCanBeCreated ?? this.nativeViewCanBeCreated,
    nativeBackdropCompositionValidated:
        nativeBackdropCompositionValidated ??
        this.nativeBackdropCompositionValidated,
    nativeSingleOverlayCompositionValidated:
        nativeSingleOverlayCompositionValidated ??
        this.nativeSingleOverlayCompositionValidated,
    nativeInteractiveEffectAvailable:
        nativeInteractiveEffectAvailable ??
        this.nativeInteractiveEffectAvailable,
    simulatedRendererAvailable:
        simulatedRendererAvailable ?? this.simulatedRendererAvailable,
    shaderAvailable: shaderAvailable ?? this.shaderAvailable,
    reducedTransparency: reducedTransparency ?? this.reducedTransparency,
    selectedAutomaticBackend:
        selectedAutomaticBackend ?? this.selectedAutomaticBackend,
    osVersion: osVersion ?? this.osVersion,
  );

  @override
  bool operator ==(Object other) =>
      other is VitreumCapabilities &&
      other.platform == platform &&
      other.nativeApiExists == nativeApiExists &&
      other.nativeViewCanBeCreated == nativeViewCanBeCreated &&
      other.nativeBackdropCompositionValidated ==
          nativeBackdropCompositionValidated &&
      other.nativeSingleOverlayCompositionValidated ==
          nativeSingleOverlayCompositionValidated &&
      other.nativeInteractiveEffectAvailable ==
          nativeInteractiveEffectAvailable &&
      other.simulatedRendererAvailable == simulatedRendererAvailable &&
      other.shaderAvailable == shaderAvailable &&
      other.reducedTransparency == reducedTransparency &&
      other.selectedAutomaticBackend == selectedAutomaticBackend &&
      other.osVersion == osVersion;

  @override
  int get hashCode => Object.hash(
    platform,
    nativeApiExists,
    nativeViewCanBeCreated,
    nativeBackdropCompositionValidated,
    nativeSingleOverlayCompositionValidated,
    nativeInteractiveEffectAvailable,
    simulatedRendererAvailable,
    shaderAvailable,
    reducedTransparency,
    selectedAutomaticBackend,
    osVersion,
  );

  @Deprecated('Use nativeApiExists.')
  bool get nativeGlassApiAvailable => nativeApiExists;

  @Deprecated('Use nativeViewCanBeCreated.')
  bool get nativeBackendAvailable => nativeViewCanBeCreated;

  @Deprecated('Use simulatedRendererAvailable.')
  bool get simulatedBackendAvailable => simulatedRendererAvailable;
}
