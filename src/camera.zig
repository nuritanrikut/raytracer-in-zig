const std = @import("std");
const RNG = @import("./rng.zig");
const vec3 = @import("./vec3.zig");
const Ray = @import("./ray.zig");

const Vector3D = @Vector(3, f64);

fn degrees_to_radians(degrees: f64) f64 {
    return degrees * std.math.pi / 180.0;
}

pub const camera_t = struct {
    origin: Vector3D,
    lower_left_corner: Vector3D,
    horizontal: Vector3D,
    vertical: Vector3D,
    u: Vector3D,
    v: Vector3D,
    w: Vector3D,
    lens_radius: f64,

    pub fn init(
        lookfrom: Vector3D,
        lookat: Vector3D,
        vup: Vector3D,
        vfov: f64, // vertical field-of-view in degrees
        aspect_ratio: f64,
        aperture: f64,
        focus_dist: f64,
    ) camera_t {
        const theta = degrees_to_radians(vfov);
        const h = std.math.tan(theta / 2.0);
        const viewport_height = 2.0 * h;
        const viewport_width = aspect_ratio * viewport_height;

        const look_direction = vec3.vec3_sub(lookfrom, lookat);
        const w = vec3.unit_vector(look_direction);

        const cross_v_w = vec3.vec3_cross(vup, w);
        const u = vec3.unit_vector(cross_v_w);

        const v = vec3.vec3_cross(w, u);

        const origin = lookfrom;
        const horizontal = vec3.vec3_scale(u, focus_dist * viewport_width);
        const vertical = vec3.vec3_scale(v, focus_dist * viewport_height);
        const horizontal_half = vec3.vec3_scale(horizontal, 0.5);
        const vertical_half = vec3.vec3_scale(vertical, 0.5);
        const focus_half = vec3.vec3_scale(w, focus_dist);

        const lower_left_corner = vec3.vec3_sub(origin, vec3.vec3_add(vec3.vec3_add(horizontal_half, vertical_half), focus_half));
        const lens_radius = aperture / 2;

        return camera_t{
            .w = w,
            .u = u,
            .v = v,
            .origin = origin,
            .horizontal = horizontal,
            .vertical = vertical,
            .lower_left_corner = lower_left_corner,
            .lens_radius = lens_radius,
        };
    }

    pub fn get_ray(self: *camera_t, rng: *RNG.random_number_generator_t, s: f64, t: f64) Ray.ray_t {
        const rd: Vector3D = vec3.vec3_scale(vec3.random_in_unit_disk(rng), self.lens_radius);
        const horizontal = vec3.vec3_scale(self.u, rd[0]);
        const vertical = vec3.vec3_scale(self.v, rd[1]);
        const offset: Vector3D = vec3.vec3_add(horizontal, vertical);

        const ray_origin = vec3.vec3_add(self.origin, offset);
        const horizontal_s = vec3.vec3_scale(self.horizontal, s);
        const vertical_t = vec3.vec3_scale(self.vertical, t);
        const ray_end = vec3.vec3_add(self.lower_left_corner, vec3.vec3_add(horizontal_s, vertical_t));
        const ray_direction = vec3.vec3_sub(ray_end, ray_origin);
        return Ray.ray_t{
            .origin = ray_origin,
            .direction = ray_direction,
        };
    }
};
