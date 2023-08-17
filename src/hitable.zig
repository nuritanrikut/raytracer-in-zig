const std = @import("std");
const HitRecord = @import("./hit_record.zig");
const Ray = @import("./ray.zig");
const Sphere = @import("./sphere.zig");

pub const hitable_t = union(enum) {
    dummy: *const fn (
        *const @This(),
        r: Ray.ray_t,
        t_min: f64,
        t_max: f64,
    ) std.os.WriteError!?HitRecord.hit_record_t,
    sphere: Sphere.sphere_t,

    pub fn hit(
        self: @This(),
        r: Ray.ray_t,
        t_min: f64,
        t_max: f64,
    ) std.os.WriteError!?HitRecord.hit_record_t {
        return switch (self) {
            .sphere => |h| h.hit(r, t_min, t_max),
            else => null,
        };
    }
};
