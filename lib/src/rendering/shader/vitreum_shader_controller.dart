import 'dart:ui' as ui;

/// Loads Vitreum's optional Impeller filter once and creates per-surface
/// shader instances so simultaneous surfaces never share mutable uniforms.
final class VitreumShaderController {
  VitreumShaderController._();

  static final VitreumShaderController instance = VitreumShaderController._();

  Future<ui.FragmentProgram?>? _program;

  bool get supported => ui.ImageFilter.isShaderFilterSupported;

  Future<ui.FragmentProgram?> load() {
    if (!supported) return Future<ui.FragmentProgram?>.value();
    return _program ??= _load();
  }

  Future<ui.FragmentProgram?> _load() async {
    try {
      return await ui.FragmentProgram.fromAsset(
        'packages/vitreum/shaders/vitreum_refraction.frag',
      );
    } on Object {
      return null;
    }
  }
}
