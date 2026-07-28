# Native iOS composition validation

## Result

**One bounded platform-view overlay is validated on the iOS 26.5 simulator
with Xcode 26.6. The generic multiple-surface architecture failed.**

Three controlled scenes isolate UIKit material behavior from Flutter
composition:

| Scene | Result |
|---|---|
| Pure native UIKit | Pass: clean, live `UIGlassEffect` sampling |
| One native glass view over Flutter | Pass: live Flutter gradient, grid, lines, and animation sampled without repeated or stretched pixels |
| Flutter simulated | Pass: stable portable comparison renderer |

Two native-over-Flutter captures at different frame numbers and background
phases confirmed that the material input updates rather than reusing a stale
frame. A subsequent cold showcase launch with two independent native platform
views reproduced missing Flutter text, split rounded cards, and stretched
regions. Therefore the one-view result must not be generalized to arbitrary
`VitreumGlass` trees. The controlled screenshots are published in
[visual_validation.md](visual_validation.md); the failed multi-view capture was
used as diagnostic evidence and is deliberately not package preview artwork.

## Root cause of the earlier corrupted result

The package contains no `drawHierarchy`, `snapshotView`,
`UIGraphicsImageRenderer`, `render(in:)`, Flutter texture, pixel-buffer, cached
screenshot, manual crop, or manual coordinate-conversion pipeline. The smeared
regions were therefore not a bad image crop.

The exact smeared-backdrop cause is multiple independent `UiKitView` glass
surfaces in the same Flutter composition. The iOS 26.5 simulator's platform
view composition produced invalid Flutter layer mapping in that topology. A
hot reconstruction and a later cold launch both reproduced the failure.

Opacity, tint, and clipping configuration also violated safe visual-effect
invariants in the earlier spike and could obscure the material response, but
correcting those values did not make the multi-view topology valid.

The validated path now enforces:

- `UIVisualEffectView.alpha == 1`;
- native host ancestors at alpha 1;
- clear effect and host backgrounds with `isOpaque == false`;
- `UIGlassEffect.tintColor == nil` unless the caller explicitly supplies tint;
- continuous corner clipping entirely inside the native view;
- native effect content added through `contentView`;
- no Flutter `Opacity`, screenshot, texture, crop, or translucent imitation
  layer around the platform view.

## Runtime gating

Generic `VitreumGlass` and automatic mode use the Flutter simulation because
`nativeBackdropCompositionValidated` is false. The separate
`VitreumNativeGlassOverlay` may use native iOS only when all of these are true:

1. `nativeApiExists`
2. `nativeViewCanBeCreated`
3. `nativeSingleOverlayCompositionValidated`

Reduced Transparency selects the solid backend. Older iOS versions and failed
native gates use the simulated renderer. Applications must use at most one
specialized native overlay per route. `VitreumGlassGroup` remains simulated
because true native grouping requires one UIKit hierarchy with
`UIGlassContainerEffect`; multiple unrelated `UiKitView` instances are never
reported as native grouping.

## Scope still requiring validation

The simulator result is strong integration evidence, not a claim that Apple's
private material implementation has been reproduced or that every Flutter
composition topology is certified. Before a production release, additionally
verify:

1. Multiple physical devices.
2. Rotation and repeated size changes.
3. Long-running animated scrolling and video.
4. Routes, sheets, dialogs, menus, keyboards, and overlay ordering.
5. Touch delivery for every interactive control topology.
6. Multiple native controls hosted in one native container rather than
   independent platform views.
7. A future native grouping implementation in one
   `UIGlassContainerEffect` hierarchy.
