/// The implementation requested for a Vitreum surface.
enum VitreumMode {
  /// Selects the best safe implementation for the current environment.
  automatic,

  /// Attempts Apple's native implementation, then falls back safely.
  native,

  /// Always uses the Flutter-rendered approximation.
  simulated,

  /// Disables blur and refraction.
  solid,
}

/// The backend selected for a surface.
enum VitreumBackend {
  /// Apple's public Liquid Glass API.
  nativeIOS,

  /// Low-cost Flutter approximation.
  flutterLow,

  /// Balanced Flutter approximation.
  flutterBalanced,

  /// Higher-detail Flutter approximation.
  flutterHigh,

  /// Opaque or translucent solid fallback.
  solid,
}

/// Normalized platform reported by Vitreum.
enum VitreumPlatform { ios, android, other }
