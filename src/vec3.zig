const std = @import("std");
const RNG = @import("./rng.zig");

const Vector3D = @Vector(3, f64);

pub fn length_squared(v: Vector3D) f64 {
    return dot(v, v);
}

pub fn length(v: Vector3D) f64 {
    return @sqrt(length_squared(v));
}

pub fn unit_vector(v: Vector3D) Vector3D {
    return vec3_scale(v, 1.0 / length(v));
}

pub fn near_zero(v: Vector3D) bool {
    const s = 1e-8;
    return (@abs(v[0]) < s) and (@abs(v[1]) < s) and (@abs(v[2]) < s);
}

pub fn vec3_write_color(stdout: anytype, color: Vector3D, samples_per_pixel: i32) !void {
    const scalef: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));

    const r: f64 = @sqrt(scalef * color[0]);
    const g: f64 = @sqrt(scalef * color[1]);
    const b: f64 = @sqrt(scalef * color[2]);

    const ri: u8 = @intFromFloat(256 * std.math.clamp(r, 0.0, 0.999));
    const gi: u8 = @intFromFloat(256 * std.math.clamp(g, 0.0, 0.999));
    const bi: u8 = @intFromFloat(256 * std.math.clamp(b, 0.0, 0.999));

    try stdout.print("{} {} {}\n", .{ ri, gi, bi });
}

pub fn vec3_cross(a: Vector3D, b: Vector3D) Vector3D {
    return Vector3D{
        a[1] * b[2] - a[2] * b[1],
        a[2] * b[0] - a[0] * b[2],
        a[0] * b[1] - a[1] * b[0],
    };
}

pub fn vec3_dot(a: Vector3D, b: Vector3D) f64 {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}

pub fn dot(a: Vector3D, b: Vector3D) f64 {
    return @reduce(.Add, a * b);
}

pub fn vec3_add(a: Vector3D, b: Vector3D) Vector3D {
    return Vector3D{
        a[0] + b[0],
        a[1] + b[1],
        a[2] + b[2],
    };
}

pub fn vec3_sub(a: Vector3D, b: Vector3D) Vector3D {
    return Vector3D{
        a[0] - b[0],
        a[1] - b[1],
        a[2] - b[2],
    };
}

pub fn vec3_scale(a: Vector3D, b: f64) Vector3D {
    return Vector3D{
        a[0] * b,
        a[1] * b,
        a[2] * b,
    };
}

fn scale(v: Vector3D, f: f64) Vector3D {
    return v * @as(Vector3D, @splat(f));
}

pub fn vec3_neg(a: Vector3D) Vector3D {
    return Vector3D{
        -a[0],
        -a[1],
        -a[2],
    };
}

pub fn random_vec3(rng: *RNG.Generator) Vector3D {
    return Vector3D{
        rng.random_f64(),
        rng.random_f64(),
        rng.random_f64(),
    };
}

pub fn random_vec3_range(rng: *RNG.Generator, min: f64, max: f64) Vector3D {
    return Vector3D{
        rng.random_range(min, max),
        rng.random_range(min, max),
        rng.random_range(min, max),
    };
}

pub fn random_in_unit_disk(rng: *RNG.Generator) Vector3D {
    var v = Vector3D{ 0, 0, 0 };
    while (true) {
        v = Vector3D{
            rng.random_range(-1.0, 1.0),
            rng.random_range(-1.0, 1.0),
            0.0,
        };
        if (length_squared(v) < 1.0) {
            return v;
        }
    }
}

pub fn random_in_unit_sphere(rng: *RNG.Generator) Vector3D {
    var v = Vector3D{ 0, 0, 0 };
    while (true) {
        v = random_vec3_range(rng, -1.0, 1.0);
        if (length_squared(v) < 1.0) {
            return v;
        }
    }
}

pub fn random_unit_vector(rng: *RNG.Generator) Vector3D {
    return unit_vector(random_in_unit_sphere(rng));
}

pub fn reflect(v: Vector3D, n: Vector3D) Vector3D {
    return vec3_sub(v, vec3_scale(n, 2.0 * vec3_dot(v, n)));
}

pub fn refract(uv: Vector3D, n: Vector3D, etai_over_etat: f64) Vector3D {
    const cos_theta = @min(vec3_dot(vec3_neg(uv), n), 1.0);
    const r_out_perp = vec3_scale(vec3_add(uv, vec3_scale(n, cos_theta)), etai_over_etat);
    const r_out_parallel = vec3_scale(n, -@sqrt(@abs(1.0 - length_squared(r_out_perp))));
    return vec3_add(r_out_perp, r_out_parallel);
}
