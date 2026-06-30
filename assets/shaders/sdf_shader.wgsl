// Begin NOISE
//  MIT License. © Ian McEwan, Stefan Gustavson, Munrocket, Johan Helsing

fn permute_3_(x: vec3<f32>) -> vec3<f32> {
    return (((x * 34.) + 1.) * x) % vec3(289.);
}

fn step_3(edge: vec3<f32>, x: vec3<f32>) -> vec3<f32> {
    let b = vec3(edge.x < x.x, edge.y <= x.y, edge.z <= x.z);
    return select(vec3(0.), vec3(1.), b);
}

fn simplex_noise_2d(v: vec2<f32>) -> f32 {
    let C = vec4(
        0.211324865405187, // (3.0 - sqrt(3.0)) / 6.0
        0.366025403784439, // 0.5 * (sqrt(3.0) - 1.0)
        -0.577350269189626, // -1.0 + 2.0 * C.x
        0.024390243902439 // 1.0 / 41.0
    );

    // first corner
    var i = floor(v + dot(v, C.yy));
    let x0 = v - i + dot(i, C.xx);

    // other corners
    var i1 = select(vec2(0., 1.), vec2(1., 0.), x0.x > x0.y);
    var x12 = x0.xyxy + C.xxzz - vec4(i1, 0., 0.);

    // permutations
    i = i % vec2(289.);

    let p = permute_3_(permute_3_(i.y + vec3(0., i1.y, 1.)) + i.x + vec3(0., i1.x, 1.));
    var m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), vec3(0.));
    m *= m;
    m *= m;

    // gradients: 41 points uniformly over a line, mapped onto a diamond
    // the ring size, 17*17 = 289, is close to a multiple of 41 (41*7 = 287)
    let x = 2. * fract(p * C.www) - 1.;
    let h = abs(x) - 0.5;
    let ox = floor(x + 0.5);
    let a0 = x - ox;

    // normalize gradients implicitly by scaling m
    // approximation of: m *= inversesqrt(a0 * a0 + h * h);
    m = m * (1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h));

    // compute final noise value at P
    let g = vec3(a0.x * x0.x + h.x * x0.y, a0.yz * x12.xz + h.yz * x12.yw);
    return 130. * dot(m, g);
}

fn simplex_noise_2d_seeded(v: vec2<f32>, seed: f32) -> f32 {
    let C = vec4(
        0.211324865405187, // (3.0 - sqrt(3.0)) / 6.0
        0.366025403784439, // 0.5 * (sqrt(3.0) - 1.0)
        -0.577350269189626, // -1.0 + 2.0 * C.x
        0.024390243902439 // 1.0 / 41.0
    );

    // first corner
    var i = floor(v + dot(v, C.yy));
    let x0 = v - i + dot(i, C.xx);

    // other corners
    var i1 = select(vec2(0., 1.), vec2(1., 0.), x0.x > x0.y);
    var x12 = x0.xyxy + C.xxzz - vec4(i1, 0., 0.);

    // permutations
    i = i % vec2(289.);

    var p = permute_3_(permute_3_(i.y + vec3(0., i1.y, 1.)) + i.x + vec3(0., i1.x, 1.));
    p = permute_3_(p + vec3(seed));
    var m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), vec3(0.));
    m *= m;
    m *= m;

    // gradients: 41 points uniformly over a line, mapped onto a diamond
    // the ring size, 17*17 = 289, is close to a multiple of 41 (41*7 = 287)
    let x = 2. * fract(p * C.www) - 1.;
    let h = abs(x) - 0.5;
    let ox = floor(x + 0.5);
    let a0 = x - ox;

    // normalize gradients implicitly by scaling m
    // approximation of: m *= inversesqrt(a0 * a0 + h * h);
    m = m * (1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h));

    // compute final noise value at P
    let g = vec3(a0.x * x0.x + h.x * x0.y, a0.yz * x12.xz + h.yz * x12.yw);
    return 130. * dot(m, g);
}

fn permute_4_(x: vec4<f32>) -> vec4<f32> {
    return ((x * 34. + 1.) * x) % vec4<f32>(289.);
}

fn taylor_inv_sqrt_4_(r: vec4<f32>) -> vec4<f32> {
    return 1.79284291400159 - 0.85373472095314 * r;
}

fn simplex_noise_3d(v: vec3<f32>) -> f32 {
    let C = vec2(1. / 6., 1. / 3.);
    let D = vec4(0., 0.5, 1., 2.);

    // first corner
    var i = floor(v + dot(v, C.yyy));
    let x0 = v - i + dot(i, C.xxx);

    // other corners
    let g = step_3(x0.yzx, x0.xyz);
    let l = 1. - g;
    let i1 = min(g.xyz, l.zxy);
    let i2 = max(g.xyz, l.zxy);

    // x0 = x0 - 0. + 0. * C
    let x1 = x0 - i1 + 1. * C.xxx;
    let x2 = x0 - i2 + 2. * C.xxx;
    let x3 = x0 - 1. + 3. * C.xxx;

    // permutations
    i = i % vec3(289.);
    let p = permute_4_(permute_4_(permute_4_(
        i.z + vec4(0., i1.z, i2.z, 1.)) +
        i.y + vec4(0., i1.y, i2.y, 1.)) +
        i.x + vec4(0., i1.x, i2.x, 1.)
    );

    // gradients (NxN points uniformly over a square, mapped onto an octahedron)
    let n_ = 1. / 7.; // N=7
    let ns = n_ * D.wyz - D.xzx;

    let j = p - 49. * floor(p * ns.z * ns.z); // mod(p, N*N)

    let x_ = floor(j * ns.z);
    let y_ = floor(j - 7. * x_); // mod(j, N)

    let x = x_ * ns.x + ns.yyyy;
    let y = y_ * ns.x + ns.yyyy;
    let h = 1. - abs(x) - abs(y);

    let b0 = vec4(x.xy, y.xy);
    let b1 = vec4(x.zw, y.zw);

    let s0 = floor(b0) * 2. + 1.;
    let s1 = floor(b1) * 2. + 1.;
    let sh = -step(h, vec4(0.));

    let a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    let a1 = b1.xzyw + s1.xzyw * sh.zzww;

    var p0 = vec3(a0.xy, h.x);
    var p1 = vec3(a0.zw, h.y);
    var p2 = vec3(a1.xy, h.z);
    var p3 = vec3(a1.zw, h.w);

    // normalize gradients
    let norm = taylor_inv_sqrt_4_(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 = p0 * norm.x;
    p1 = p1 * norm.y;
    p2 = p2 * norm.z;
    p3 = p3 * norm.w;

    // mix final noise value
    var m = 0.5 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3));
    m = max(m, vec4(0.));
    m *= m;
    return 105. * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

fn simplex_noise_3d_seeded(v: vec3<f32>, seed: vec3<f32>) -> f32 {
    let C = vec2(1. / 6., 1. / 3.);
    let D = vec4(0., 0.5, 1., 2.);

    // first corner
    var i = floor(v + dot(v, C.yyy));
    let x0 = v - i + dot(i, C.xxx);

    // other corners
    let g = step_3(x0.yzx, x0.xyz);
    let l = 1. - g;
    let i1 = min(g.xyz, l.zxy);
    let i2 = max(g.xyz, l.zxy);

    // x0 = x0 - 0. + 0. * C
    let x1 = x0 - i1 + 1. * C.xxx;
    let x2 = x0 - i2 + 2. * C.xxx;
    let x3 = x0 - 1. + 3. * C.xxx;

    // permutations
    i = i % vec3(289.);
    let s = floor(seed + vec3(0.5));
    let p = permute_4_(permute_4_(permute_4_(
        i.z + vec4(0., i1.z, i2.z, 1.) + s.z) +
        i.y + vec4(0., i1.y, i2.y, 1.) + s.y) +
        i.x + vec4(0., i1.x, i2.x, 1.) + s.x
    );

    // gradients (NxN points uniformly over a square, mapped onto an octahedron)
    let n_ = 1. / 7.; // N=7
    let ns = n_ * D.wyz - D.xzx;

    let j = p - 49. * floor(p * ns.z * ns.z); // mod(p, N*N)

    let x_ = floor(j * ns.z);
    let y_ = floor(j - 7. * x_); // mod(j, N)

    let x = x_ * ns.x + ns.yyyy;
    let y = y_ * ns.x + ns.yyyy;
    let h = 1. - abs(x) - abs(y);

    let b0 = vec4(x.xy, y.xy);
    let b1 = vec4(x.zw, y.zw);

    let s0 = floor(b0) * 2. + 1.;
    let s1 = floor(b1) * 2. + 1.;
    let sh = -step(h, vec4(0.));

    let a0 = b0.xzyw + s0.xzyw * sh.xxyy;
    let a1 = b1.xzyw + s1.xzyw * sh.zzww;

    var p0 = vec3(a0.xy, h.x);
    var p1 = vec3(a0.zw, h.y);
    var p2 = vec3(a1.xy, h.z);
    var p3 = vec3(a1.zw, h.w);

    // normalize gradients
    let norm = taylor_inv_sqrt_4_(vec4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
    p0 = p0 * norm.x;
    p1 = p1 * norm.y;
    p2 = p2 * norm.z;
    p3 = p3 * norm.w;

    // mix final noise value
    var m = 0.6 - vec4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3));
    m = max(m, vec4(0.));
    m *= m;
    return 42. * dot(m * m, vec4(dot(p0, x0), dot(p1, x1), dot(p2, x2), dot(p3, x3)));
}

// higher level concepts:

/// Fractional brownian motion (fbm) based on 2d simplex noise
fn fbm_simplex_2d(pos: vec2<f32>, octaves: i32, lacunarity: f32, gain: f32) -> f32 {
    var sum = 0.;
    var amplitude = 1.;
    var frequency = 1.;

    for (var i = 0; i < octaves; i+= 1) {
        sum += simplex_noise_2d(pos * frequency) * amplitude;
        amplitude *= gain;
        frequency *= lacunarity;
    }

    return sum;
}

/// Fractional brownian motion (fbm) based on seeded 2d simplex noise
fn fbm_simplex_2d_seeded(pos: vec2<f32>, octaves: i32, lacunarity: f32, gain: f32, seed: f32) -> f32 {
    var sum = 0.;
    var amplitude = 1.;
    var frequency = 1.;

    for (var i = 0; i < octaves; i+= 1) {
        sum += simplex_noise_2d_seeded(pos * frequency, seed) * amplitude;
        amplitude *= gain;
        frequency *= lacunarity;
    }

    return sum;
}

const max_warp_iterations: i32 = 4; // Warping has diminishing returns due to the falloff param, so we don't need many iterations. Faloff makes it look more natural.

struct WarpResult {
    noise_value: f32,
    // The history of warped coordinates, where positions[0] is the last iteration, positions[1] is second to last, etc.
    // Can be useful for mixing colors.
    positions: array<vec2f, max_warp_iterations>
}

/// A technique that distorts the position before feeding it to the noise
/// inspired by https://iquilezles.org/articles/warp/
fn fbm_simplex_2d_warp_seeded(pos_initial: vec2<f32>, octaves: i32, lacunarity: f32, gain: f32, seed: f32, warp_iterations: i32, warp_scale: vec2<f32>, falloff: f32) -> WarpResult {
    var scale = 1.0;
    var positions = array<vec2f, max_warp_iterations>();
    var pos = pos_initial;

    // Clamp warp_iterations to max_warp_iterations
    let iterations = min(warp_iterations, i32(max_warp_iterations));

    for (var i: i32 = 0; i < iterations; i++) {
        pos.x += scale * warp_scale.x * fbm_simplex_2d_seeded(pos, octaves, lacunarity, gain, seed);
        pos.y += scale * warp_scale.y * fbm_simplex_2d_seeded(pos, octaves, lacunarity, gain, seed);

        // Store positions in reverse order for easier user access (last iteration at index 0)
        let index = max_warp_iterations - 1 - i;
        if (index < max_warp_iterations) {
            positions[index] = pos;
        }

        scale *= falloff;
    }

    let noise_value = fbm_simplex_2d_seeded(positions[0], octaves, lacunarity, gain, seed);

    return WarpResult(noise_value, positions);
}

/// Fractional brownian motion (fbm) based on 3d simplex noise
fn fbm_simplex_3d(pos: vec3<f32>, octaves: i32, lacunarity: f32, gain: f32) -> f32 {
    var sum = 0.;
    var amplitude = 1.;
    var frequency = 1.;

    for (var i = 0; i < octaves; i+= 1) {
        sum += simplex_noise_3d(pos * frequency) * amplitude;
        amplitude *= gain;
        frequency *= lacunarity;
    }

    return sum;
}

/// Fractional brownian motion (fbm) based on seeded 3d simplex noise
fn fbm_simplex_3d_seeded(pos: vec3<f32>, octaves: i32, lacunarity: f32, gain: f32, seed: vec3<f32>) -> f32 {
    var sum = 0.;
    var amplitude = 1.;
    var frequency = 1.;

    for (var i = 0; i < octaves; i+= 1) {
        sum += simplex_noise_3d_seeded(pos * frequency, seed) * amplitude;
        amplitude *= gain;
        frequency *= lacunarity;
    }

    return sum;
}

// MIT license, ported from https://github.com/bevy-interstellar/wgsl_noise
/// Cellular noise, lower jitter makes the patern more regular
/// The x component (F1) of the returned result represents the distance to the nearest feature point from the input position
/// The y component (F2) represents the distance to the second nearest feature point from the input position
fn worley_2d(pos: vec2<f32>, jitter: f32) -> vec2<f32> {
    let k = 0.142857142857; // 1/7
    let ko = 0.428571428571; // 3/7

    // Determine the grid cell and fractional position
    let pi = floor(pos);
    let pf = fract(pos);

    // Define offset indices for neighboring grid cells
    let oi = vec3(-1.0, 0.0, 1.0);
    let of_ = vec3(-0.5, 0.5, 1.5);

    // Permute the grid cell indices to get unique values for each cell
    let px = permute_3_(pi.x + oi);
    var p = permute_3_(px.x + pi.y + oi);  // p11, p12, p13

    var ox = fract(p * k) - ko;
    var oy = (floor(p * k) % 7.0) * k - ko;
    var dx = pf.x + 0.5 + jitter * ox;
    var dy = pf.y - of_ + jitter * oy;
    var d1 = dx * dx + dy * dy;  // d11, d12, d13, squared

    p = permute_3_(px.y + pi.y + oi); // p21, p22, p23
    ox = fract(p * k) - ko;
    oy = (floor(p * k) % 7.0) * k - ko;
    dx = pf.x - 0.5 + jitter * ox;
    dy = pf.y - of_ + jitter * oy;
    var d2 = dx * dx + dy * dy; // d21, d22, d23, squared

    p = permute_3_(px.z + pi.y + oi); // p31, p32, p33
    ox = fract(p * k) - ko;
    oy = (floor(p * k) % 7.0) * k - ko;
    dx = pf.x - 1.5 + jitter * ox;
    dy = pf.y - of_ + jitter * oy;
    let d3 = dx * dx + dy * dy; // d31, d32, d33, squared

    // Sort out the two smallest distances (F1, F2)
    let d1a = min(d1, d2);
    d2 = max(d1, d2);               // Swap to keep candidates for F2
    d2 = min(d2, d3);               // neither F1 nor F2 are now in d3
    d1 = min(d1a, d2);              // F1 is now in d1
    d2 = max(d1a, d2);              // Swap to keep candidates for F2

    if d1.x > d1.y {                // Swap if smaller
        let tmp = d1.x;
        d1.x = d1.y;
        d1.y = tmp;
    }
    if d1.x > d1.z {                // F1 is in d1.x
        let tmp = d1.x;
        d1.x = d1.z;
        d1.z = tmp;
    }

    d1.y = min(d1.y, d2.y);         // F2 is now not in d2.yz
    d1.z = min(d1.z, d2.z);
    d1.y = min(d1.y, d1.z);         // nor in  d1.z
    d1.y = min(d1.y, d2.x);         // F2 is in d1.y, we're done.
    return sqrt(d1.xy);
}
// End NOISE

// Begin SDF
fn circle(p: vec2f, r: f32) -> f32 
{
    return length(p)-r;
}

fn rect(p: vec2f, b: vec2f) -> f32 {
    let d: vec2f = abs(p)-b;
    let max_component = vec2f(max(d.x, 0.0), max(d.y, 0.0));
    return length(max_component) + min(max(d.x,d.y),0.0);
}

fn segment(p: vec2f, a: vec2f, b: vec2f) -> f32 {
    let pa = p-a;
    let ba = b-a;
    let h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h);
}

fn ellipse(po: vec2f, abo: vec2f) -> f32 {
    var p: vec2f = abs(po);
    var ab = abo;
    if p.x > p.y  {
        p=p.yx;
        ab=ab.yx;
    }
    let l: f32 = ab.y*ab.y - ab.x*ab.x;
    let m: f32 = ab.x*p.x/l;      
    let m2: f32 = m*m; 
    let n: f32 = ab.y*p.y/l;
    let n2: f32 = n*n; 
    let c: f32 = (m2+n2-1.0)/3.0;
    let c3: f32 = c*c*c;
    let q: f32 = c3 + m2*n2*2.0;
    let d: f32 = c3 + m2*n2;
    let g: f32 = m + m*n2;
    var co: f32 = 0;
    if d<0.0  {
        let h: f32 = acos(q/c3)/3.0;
        let s: f32 = cos(h);
        let t = sin(h)*sqrt(3.0);
        let rx = sqrt( -c*(s + t + 2.0) + m2 );
        let ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
    } else {
        let h = 2.0*m*n*sqrt( d );
        let s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
        let u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
        let rx = -s - u - c*4.0 + 2.0*m2;
        let ry = (s - u)*sqrt(3.0);
        let rm = sqrt( rx*rx + ry*ry );
        co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
    }
    let r: vec2f = ab * vec2f(co, sqrt(1.0-co*co));
    return length(r-p) * sign(p.y-r.y);
}

fn debug_colors(d: f32) -> vec4f {
    //  vec3 col = (d>0.0) ? vec3(0.9,0.6,0.3) : ;
    // col *= 1.0 - exp(-6.0*abs(d));
	// col *= 0.8 + 0.2*cos(150.0*d);
	// col = mix( col, vec3(1.0), 1.0-smoothstep(0.0,0.01,abs(d)) );
    // coloring
    var col = vec3f(0.9,0.6,0.3);
    if d < 0.0 {
        col = vec3f(0.65,0.85,1.0);
    }
    col *= 1.0 - exp(-6.0*abs(d));
    col *= 0.8 + 0.2*cos(150.0*d);
    col = mix(col, vec3f(1.0), 1.0-smoothstep(0.0,0.01,abs(d)));    
    return vec4f(col, 1);
}

fn grow(d: f32, r: f32) ->  f32 {
    return (d - r);
}

fn intersect(d1: f32, d2: f32) -> f32 {
    return max(d1, d2);
}

fn merge(d1: f32, d2: f32) -> f32 {
    return min(d1, d2);
}

fn translate(uv: vec2f, delta: vec2f) -> vec2f {
    return uv + delta;
}

fn scale(p: vec2f, s: f32) -> vec2f {
    return p / s;
}

fn rotate(p: vec2f, rotation: f32) -> vec2f {
    let PI = 3.14159;
    let angle = rotation * PI * 2 * -1;
    var sine: f32 = sin(angle);
    var cosine: f32 = cos(angle);    
    return vec2f(cosine * p.x + sine * p.y, cosine * p.y - sine * p.x);
}

fn difference(d1: f32, d2: f32) -> f32 {
    return intersect(d1, -d2);
}

fn smooth_merge(d1: f32, d2: f32, r: f32) -> f32 {
    var intersection_space = vec2f(d1 - r, d2 - r);
    intersection_space = min(intersection_space, vec2f(0));

    let inside_distance = -length(intersection_space);
    let simple_union = merge(d1, d2);
    let outside_distance = max(simple_union, r);
    return  inside_distance + outside_distance;
}

fn shape_edge(d: f32) -> f32 {
    return abs(d);
}

fn alpha_blend(a: vec4f, b: vec4f) -> vec4f {
    return mix(b, a, a.a);
}

fn shade(d: f32, c: vec4f) -> vec4f {    
    return mix(vec4f(0), c, step(d, 0.0));
}

// End SDF

// Begin COLOR_PALETTE

// End COLOR_PALETTE


struct FullscreenVertexOutput {
    @builtin(position)
    position: vec4<f32>,
    @location(0)
    uv: vec2<f32>,
};


@group(0) @binding(0) var screen_texture: texture_2d<f32>;
@group(0) @binding(1) var texture_sampler: sampler;

struct FullScreenEffect {
    time: f32,
    screen_size: vec2<f32>,
    cursor_position: vec3<f32>,
    _padding: f32
}

@group(0) @binding(2) var<uniform> settings: FullScreenEffect;

fn uv_correction() -> vec2f {
    if(settings.screen_size.x > settings.screen_size.y) {
        return vec2f(settings.screen_size.x / settings.screen_size.y, 1);
    }
    return vec2f(1, settings.screen_size.y / settings.screen_size.x);
}

@fragment
fn fragment(in: FullscreenVertexOutput) -> @location(0) vec4<f32> {
    let correction = uv_correction();
    let has_cursor = settings.cursor_position.z;
    let cursor_position = 2*(settings.cursor_position.xy - vec2f(0.5)) * correction;    
    let uv = 2*(in.uv.xy - vec2f(0.5)) * correction;

    var d = circle(uv, 0.5);
    d = rect(uv, vec2f(0.4, 0.3));
    d = segment(uv, vec2f(0, 0), vec2f(0.5, 0.5));
    let t = mix(0.2, 0.4, abs(sin(settings.time)));
    d = ellipse(uv, vec2f(0.5, t)); 

    // d = grow(rect(uv, vec2f(0.2, 0.1)), 0.1);
    
    let cursor = circle(uv - cursor_position, 0.1);
    d = mix(d, smooth_merge(d, cursor, 0.1), has_cursor);
    let line = shade(grow(shape_edge(d), 0.01), vec4f(0, 0, 0, 1));
    let fill = shade(d, vec4f(0.3, 0.0, 0.8, 1.0));
    
    let background = vec4f(0.7, 0.8, 0.95, 1.0);
    return alpha_blend(alpha_blend(line, fill), background);    
    // return debug_colors(d);    
}