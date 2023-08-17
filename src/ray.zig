const std = @import("std");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const ray_t = struct {
    origin: Vector3D,
    direction: Vector3D,

    pub fn at(self: *const ray_t, t: f64) Vector3D {
        return Vec3.vec3_add(self.origin, Vec3.vec3_scale(self.direction, t));
    }
};
