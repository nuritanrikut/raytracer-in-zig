const std = @import("std");
const Hitable = @import("./hitable.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const hit_record_t = struct {
    p: Vector3D,
    normal: Vector3D,
    material: Material.material_t,
    t: f64,
    front_face: bool,

    pub fn init() hit_record_t {
        return hit_record_t{
            .p = Vector3D{ 0, 0, 0 },
            .normal = Vector3D{ 0, 0, 0 },
            .material = Material.material_t.init(),
            .t = std.math.inf(f64),
            .front_face = false,
        };
    }

    pub fn set_face_normal(self: *hit_record_t, r: Ray.ray_t, outward_normal: Vector3D) void {
        self.front_face = Vec3.vec3_dot(r.direction, outward_normal) < 0.0;
        if (self.front_face) {
            self.normal = outward_normal;
        } else {
            self.normal = Vec3.vec3_neg(outward_normal);
        }
    }
};
