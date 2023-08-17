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
        // const stderr_file = std.io.getStdErr().writer();
        // var bwerr = std.io.bufferedWriter(stderr_file);
        // const stderr = bwerr.writer();
        var result = .{
            .center = center,
            .radius = radius,
            .material = material,
        };
        // try stderr.print(
        //     "!!! creating sphere ({d:.4}, {d:.4}, {d:.4}) {d:.4}\n",
        //     .{
        //         result.center[0],
        //         result.center[1],
        //         result.center[2],
        //         result.radius,
        //     },
        // );
        // try bwerr.flush();
        return result;
    }

    pub fn hit(
        self: @This(),
        r: Ray.Ray,
        t_min: f64,
        t_max: f64,
    ) std.os.WriteError!?HitRecord.HitRecord {
        // const stderr_file = std.io.getStdErr().writer();
        // var bwerr = std.io.bufferedWriter(stderr_file);
        // const stderr = bwerr.writer();

        const oc = Vec3.vec3_sub(r.origin, self.center);
        const a = Vec3.length_squared(r.direction);
        const half_b = Vec3.vec3_dot(oc, r.direction);
        const c = Vec3.length_squared(oc) - self.radius * self.radius;

        // try stderr.print(
        //     "!!! checking sphere ({d:.4}, {d:.4}, {d:.4}) {d:.4} | ray ({d:.4}, {d:.4}, {d:.4}) ({d:.4}, {d:.4}, {d:.4})\n",
        //     .{
        //         self.center[0],
        //         self.center[1],
        //         self.center[2],
        //         self.radius,
        //         r.origin[0],
        //         r.origin[1],
        //         r.origin[2],
        //         r.direction[0],
        //         r.direction[1],
        //         r.direction[2],
        //     },
        // );
        // try bwerr.flush();

        const discriminant = half_b * half_b - a * c;
        if (discriminant < 0) {
            // try stderr.print(
            //     "!!! checking sphere discriminant < 0\n",
            //     .{},
            // );
            // try bwerr.flush();
            return null;
        }
        const sqrtd = @sqrt(discriminant);
        var t = (-half_b - sqrtd) / a;
        if (t < t_min or t_max < t) {
            t = (-half_b + sqrtd) / a;
            if (t < t_min or t_max < t) {
                // try stderr.print(
                //     "!!! checking sphere t is out of bounds\n",
                //     .{},
                // );
                // try bwerr.flush();
                return null;
            }
        }

        // try stderr.print(
        //     "!!! checking sphere hit\n",
        //     .{},
        // );
        // try bwerr.flush();

        var result = HitRecord.HitRecord.init();
        result.t = t;
        result.p = r.at(t);
        result.material = self.material;
        result.set_face_normal(r, Vec3.vec3_scale(Vec3.vec3_sub(result.p, self.center), 1 / self.radius));
        return result;
    }
};
