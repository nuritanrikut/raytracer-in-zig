const std = @import("std");
const Hitable = @import("./hitable.zig");
const HitRecord = @import("./hit_record.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const Sphere = struct {
    center: Vector3D,
    radius: f64,
    material: Material.Material,

    pub fn init(center: Vector3D, radius: f64, material: Material.Material) !@This() {
        const result = .{
            .center = center,
            .radius = radius,
            .material = material,
        };
        return result;
    }

    pub fn hit(
        self: @This(),
        r: *const Ray.Ray,
        t_min: f64,
        t_max: f64,
    ) ?HitRecord.HitRecord {
        const oc = Vec3.vec3_sub(r.origin, self.center);
        const a = Vec3.length_squared(r.direction);
        const half_b = Vec3.vec3_dot(oc, r.direction);
        const c = Vec3.length_squared(oc) - self.radius * self.radius;

        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0) {
            return null;
        }
        const sqrtd = @sqrt(discriminant);
        var t = (-half_b - sqrtd) / a;
        if (t < t_min or t_max < t) {
            t = (-half_b + sqrtd) / a;
            if (t < t_min or t_max < t) {
                return null;
            }
        }

        var result = HitRecord.HitRecord.init();
        result.t = t;
        result.p = r.at(t);
        result.material = self.material;
        result.set_face_normal(r, Vec3.vec3_scale(Vec3.vec3_sub(result.p, self.center), 1 / self.radius));
        return result;
    }
};
