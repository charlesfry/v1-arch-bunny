// bunne-grid.frag — MegaUltraBunny wallpaper prototype (2026-08-25).
// Matte #0f0f0f, neon pink->cyan synthwave floor grid scrolling slowly,
// soft horizon glow with a slow pulse, faint CRT scanlines.
uniform vec2 resolution;
uniform float time;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / resolution;
    vec3 col = vec3(0.059); // #0f0f0f
    vec3 neon = mix(vec3(1.0, 0.18, 0.77), vec3(0.0, 1.0, 0.84), uv.x);

    float horizon = 0.35;
    if (uv.y < horizon) {
        float d = (horizon - uv.y) / horizon;    // 0 at horizon, 1 at bottom
        float z = 1.0 / (d + 0.02);
        float xw = (uv.x - 0.5) * z;
        float zw = z + time * 0.9;
        float lx = abs(fract(xw * 1.5) - 0.5);
        float lz = abs(fract(zw * 1.5) - 0.5);
        float grid = smoothstep(0.06, 0.0, lx) + smoothstep(0.06, 0.0, lz);
        col += neon * grid * 0.35 * d;
    }

    float glow = exp(-abs(uv.y - horizon) * 18.0);
    col += neon * glow * 0.12 * (0.8 + 0.2 * sin(time * 0.6));

    col *= 1.0 - 0.04 * sin(fragCoord.y * 3.14159);
    fragColor = vec4(col, 1.0);
}
