#version 460 core
#include <flutter/runtime_effect.glsl>

// The engine supplies the input size and backdrop texture.
uniform vec2 u_size;
uniform float u_refraction;
uniform float u_chromatic;
uniform float u_blurRadius;
uniform sampler2D u_texture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  vec2 centered = uv * 2.0 - 1.0;
  float distanceFromCenter = length(centered);
  vec2 normal = centered / max(distanceFromCenter, 0.001);

  // Concentrate lensing near the perimeter and keep the center stable.
  float lens = smoothstep(0.34, 1.0, distanceFromCenter);
  lens *= 1.0 - smoothstep(1.0, 1.38, distanceFromCenter);
  vec2 displaced = clamp(
    uv - normal * lens * u_refraction * 0.018,
    vec2(0.002),
    vec2(0.998)
  );

  // Five restrained samples provide a low-cost, locally bounded softening.
  vec2 texel = vec2(1.0) / u_size;
  vec2 radius = texel * u_blurRadius;
  vec4 color = texture(u_texture, displaced) * 0.40;
  color += texture(u_texture, displaced + vec2(radius.x, 0.0)) * 0.15;
  color += texture(u_texture, displaced - vec2(radius.x, 0.0)) * 0.15;
  color += texture(u_texture, displaced + vec2(0.0, radius.y)) * 0.15;
  color += texture(u_texture, displaced - vec2(0.0, radius.y)) * 0.15;

  // Very small edge-only spectral separation; disabled by lower qualities.
  vec2 spectralOffset = normal * lens * u_chromatic * 0.006;
  float red = texture(u_texture, clamp(displaced + spectralOffset, 0.0, 1.0)).r;
  float blue = texture(u_texture, clamp(displaced - spectralOffset, 0.0, 1.0)).b;
  color.r = mix(color.r, red, min(u_chromatic * 8.0, 0.16));
  color.b = mix(color.b, blue, min(u_chromatic * 8.0, 0.16));

  // Subtle local dynamic-range adaptation helps the material separate without
  // turning it into an opaque or glowing surface.
  float luminance = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  float adaptation = mix(0.025, -0.018, smoothstep(0.42, 0.72, luminance));
  color.rgb = clamp(color.rgb + adaptation, 0.0, 1.0);
  fragColor = color;
}
