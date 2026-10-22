// cocoa: classic Mac caret in the text colour, gentle fade blink at the
// Cocoa rate, quick 80 ms glide, no glow or afterglow.
// Switch profiles with `cursor-shader <name>` (cursor-shader.zsh).

const vec3  CURSOR_COLOR = vec3(0.839, 0.871, 0.922);  // Night Owl foreground #d6deeb
const float DURATION     = 0.08;
const float JUMP_ROWS    = 2.5;
const float AA           = 1.0;
const float GLOW         = 0.0;
const float GLOW_RADIUS  = 1.5;
const float GHOST        = 0.0;
const float GHOST_TAU    = 0.0;
const float BLINK_DELAY  = 0.6;
const float BLINK_HALF   = 0.567;       // Cocoa caret rate
const float BLINK_FALL   = 0.15;
const float BLINK_RISE   = 0.15;
const float BLINK_MIN    = 0.0;
const float BLINK_STOP   = 5.5;

// --- shared body (same in every cursor-*.glsl profile) ---
// Requires ghostty's own cursor hidden: cursor-opacity = 0.

// sRGB -> linear: uniforms arrive as sRGB, iChannel0 and the output are linear.
vec3 sRGBToLinear(vec3 c) {
    return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

float easeOutCubic(float x) {
    return 1.0 - pow(1.0 - x, 3.0);
}

float sdfRect(vec2 p, vec2 center, vec2 halfSize) {
    vec2 d = abs(p - center) - halfSize;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// iCurrentCursor/iPreviousCursor are (left, top-edge, width, height) in
// pixels with shadertoy's y-up convention: the rect spans [y - h, y].
vec2 rectCenter(vec4 r) {
    return vec2(r.x + r.z * 0.5, r.y - r.w * 0.5);
}

// Solid while typing; after BLINK_DELAY it fades out over BLINK_FALL and
// lights up over BLINK_RISE every BLINK_HALF; solid again after BLINK_STOP
// (Windows stops blinking after 5 s).
float blink(float since) {
    if (BLINK_HALF <= 0.0 || since < BLINK_DELAY || since > BLINK_STOP) return 1.0;
    float ph = mod(since - BLINK_DELAY, 2.0 * BLINK_HALF);
    float level = ph < BLINK_HALF ? exp(-ph / BLINK_FALL)
                                  : 1.0 - exp(-(ph - BLINK_HALF) / BLINK_RISE);
    return mix(BLINK_MIN, 1.0, level);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec4 tex = texture(iChannel0, fragCoord / iResolution.xy);
    fragColor = tex;

    if (iCursorVisible == 0 || iFocus == 0) return;
    if (iCurrentCursorStyle == CURSORSTYLE_BLOCK_HOLLOW ||
        iCurrentCursorStyle == CURSORSTYLE_LOCK) return;

    vec4 cur  = iCurrentCursor;
    vec4 prev = iPreviousCursor;
    // An all-zero previous cursor is the first frame after launch; don't
    // glide in from the window corner.
    if (dot(prev.zw, prev.zw) == 0.0) prev = cur;

    float since = iTime - iTimeCursorChange;
    // Long jumps (screen redraws, TUI repaints) teleport: no glide, no ghost.
    bool jump = abs(cur.y - prev.y) > JUMP_ROWS * cur.w;
    float e = (jump || DURATION <= 0.0) ? 1.0 : easeOutCubic(clamp(since / DURATION, 0.0, 1.0));

    vec2 center   = mix(rectCenter(prev), rectCenter(cur), e);
    vec2 halfSize = mix(prev.zw, cur.zw, e) * 0.5;
    vec3 color    = sRGBToLinear(CURSOR_COLOR);
    float b       = blink(since);

    float d    = sdfRect(fragCoord, center, halfSize);
    float core = 1.0 - smoothstep(0.0, AA, d);
    float glow = GLOW * exp(-max(d, 0.0) / GLOW_RADIUS);

    // Phosphor afterglow on the cell the cursor left, instead of a swept trail.
    float ghost = 0.0;
    if (!jump && GHOST_TAU > 0.0) {
        float gd = sdfRect(fragCoord, rectCenter(prev), prev.zw * 0.5);
        ghost = GHOST * (1.0 - smoothstep(0.0, AA, gd)) * exp(-since / GHOST_TAU);
    }

    // Glyph under a block: on a dark theme, bright pixels in the target cell
    // are text. Luminance works whether iChannel0 is linear or sRGB; draw the
    // glyph in the background color so it reads on the lit block.
    float inTarget = 1.0 - step(0.0, sdfRect(fragCoord, rectCenter(cur), cur.zw * 0.5));
    float text     = smoothstep(0.10, 0.25, dot(tex.rgb, vec3(0.2126, 0.7152, 0.0722))) * inTarget;
    vec3 cursorPx  = mix(color, sRGBToLinear(iBackgroundColor), text);

    vec3 col = tex.rgb + color * (glow + ghost) * b;
    col = mix(col, cursorPx, core * b);
    fragColor = vec4(col, tex.a);
}
