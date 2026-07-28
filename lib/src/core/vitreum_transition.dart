/// Material transition behavior for showing or moving a glass control.
enum VitreumTransitionType {
  /// Uses Flutter matched geometry through a shared Hero tag.
  matchedGeometry,

  /// Appears or disappears with restrained opacity and scale.
  materialize,

  /// Applies no material-specific transition.
  identity,
}
