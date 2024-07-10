const std = @import("std");
const Hitable = @import("./hitable.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const HitRecord = struct {
    p: Vector3D,
    normal: Vector3D,
    material: Material.Material,
    t: f64,
    front_face: bool,

    pub fn init() HitRecord {
        return HitRecord{
            .p = Vector3D{ 0, 0, 0 },
            .normal = Vector3D{ 0, 0, 0 },
            .material = Material.Material.init(),
            .t = std.math.inf(f64),
            .front_face = false,
        };
    }

    pub fn set_face_normal(self: *HitRecord, r: *const Ray.Ray, outward_normal: Vector3D) void {
        self.front_face = Vec3.vec3_dot(r.direction, outward_normal) < 0.0;
        if (self.front_face) {
            self.normal = outward_normal;
        } else {
            self.normal = Vec3.vec3_neg(outward_normal);
        }
    }
};
