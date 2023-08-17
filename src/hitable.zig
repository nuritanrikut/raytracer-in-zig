const std = @import("std");
const HitRecord = @import("./hit_record.zig");
const Ray = @import("./ray.zig");
const Sphere = @import("./sphere.zig");

pub const Hitable = union(enum) {
    dummy: *const fn (
        *const @This(),
        r: Ray.Ray,
        t_min: f64,
        t_max: f64,
    ) std.os.WriteError!?HitRecord.HitRecord,
    sphere: Sphere.Sphere,

    pub fn hit(
        self: @This(),
        r: Ray.Ray,
        t_min: f64,
        t_max: f64,
    ) std.os.WriteError!?HitRecord.HitRecord {
        return switch (self) {
            .sphere => |h| h.hit(r, t_min, t_max),
            else => null,
        };
    }
};
