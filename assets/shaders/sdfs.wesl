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

fn ellipse(p: vec2f, ab: vec2f) -> f32 {
    let k1 = length(p / ab);
    let k2 = length(p / (ab*ab));
    return k1*(k1-1.0)/k2;   
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
    return mix(b, a, saturate(a.a));
}

fn shade(d: f32, c: vec4f) -> vec4f {
    let f = fwidth(d);
    let s_f = smoothstep(f, -f, d);
    return mix(vec4f(0), c, s_f);
}