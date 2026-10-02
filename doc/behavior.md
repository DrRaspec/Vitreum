# Interaction and motion behavior

Vitreum follows observable principles in Apple's public Liquid Glass material,
while using original Flutter and platform code. These values are Vitreum
choices; they are not represented as Apple's private constants.

References:

- [Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Build a SwiftUI app with the new design](https://developer.apple.com/videos/play/wwdc2025/323/)
- [Build a UIKit app with the new design](https://developer.apple.com/videos/play/wwdc2025/284/)
- [Motion guidelines](https://developer.apple.com/design/human-interface-guidelines/motion)

## Default Vitreum timing values

| Behavior | Vitreum value | Curve |
|---|---:|---|
| Touch-down flex | 120 ms | `easeOutCubic` |
| Illumination arrival | 75 ms | `easeOutCubic` |
| Illumination release | 160 ms | `easeInOutCubic` |
| Materialize transition | 180 ms | `easeInOutCubic` |
| Group size coordination | 180 ms | `easeInOutCubic` |
| Bar minimize/restore | 180 ms | `easeInOutCubic` |

Animations remain interruptible because their target values update through
Flutter's implicit animations. Reduce Motion replaces flex and material scale
with immediate or opacity-only changes. Button flex duration, curve, scale,
highlight boost, shadow factor, and minimum target size can be customized with
`VitreumInteractionStyle`; see [Customization](customization.md).

## Quality degradation

| Quality | Idle | Interaction | Grouping |
|---|---|---|---|
| Low | Bounded blur, tint, partial edge light | Small scale only | Shared backdrop, no merge halo |
| Balanced | Bounded blur and theme-aware separation | Touch illumination and restrained flex | Shared backdrop and soft proximity blend |
| High | Five-sample Impeller filter with edge lensing | Touch-position illumination and slightly stronger lensing | Same grouping with higher optical detail |
| Solid | Nearly opaque surface | Standard scale/focus feedback | No optical merge |

The optional shader is loaded once. Each surface owns its mutable shader
instance, and unsupported renderers use bounded blur without throwing.

## Group approximation

`VitreumGlassGroup` preserves individual layout, semantics, and hit targets. It
shares backdrop sampling and uses a very low-opacity proximity field controlled
by `spacing`. As externally animated controls approach, these fields blend
without introducing a second interactive layer. This is not a geometric clone
of Apple's private merge renderer.

## Scroll behavior

`VitreumGlassBar`, `VitreumGlassNavigationBar`, and
`VitreumNativeGlassNavigationBar` can listen to one `ScrollController`:

- `minimizeOnScroll` minimizes after 28 logical pixels of sustained downward
  user travel and restores after 16 logical pixels upward.
- Raw pixel deltas are normalized with the attached vertical
  `AxisDirection`, so `reverse: true` chat lists use screen-correct directions.
- Tiny reversals reset the accumulated direction distance instead of toggling
  immediately.
- Idle and programmatic offset changes are ignored for minimization. Keyboard
  avoidance, state restoration, and application scroll commands therefore do
  not change the minimized state.
- Reaching the controller's initial edge restores the bar. Non-scrollable and
  horizontal positions do not drive minimization. Unattached and multiply
  attached controllers are ignored rather than accessed through an invalid
  single-position assumption.
- Minimized navigation remains visible at 90% scale. The default translation
  is zero, preserving the caller's safe-area placement.
- `expandOnInteraction` defaults to true; set it to false to keep the compact
  state while destinations are activated.
- `scrollEdgeTreatment` slightly increases simulated surface separation after
  content moves underneath.

Listeners are attached once, replaced when the controller changes, and
removed during disposal. State rebuilds occur only when minimized or edge
treatment state changes—not for every scroll pixel. No shader is rebuilt and
no platform-channel message is sent for a scroll event.

## Background validation checklist

Before shipping a screen, inspect regular and clear styles over:

- white, black, and mid-grey;
- colorful gradients and detailed imagery;
- moving, text-heavy, and video content;
- reduced transparency, increased contrast, and reduced motion.

High quality performs local luminance adjustment in the filter. Other quality
tiers use application brightness and accessibility context; foreground glyphs
do not automatically sample and flip color.
