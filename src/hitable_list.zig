const std = @import("std");
const HitRecord = @import("./hit_record.zig");
const Hitable = @import("./hitable.zig");
const Ray = @import("./ray.zig");

pub const HitableList = struct {
    objects: std.ArrayList(Hitable.Hitable),

    pub fn init(allocator: std.mem.Allocator) HitableList {
        return HitableList{
            .objects = std.ArrayList(Hitable.Hitable).init(allocator),
        };
    }

    pub fn deinit(self: *HitableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HitableList, obj: Hitable.Hitable) !void {
        try self.objects.append(obj);
    }

    pub fn hit(self: HitableList, r: *const Ray.Ray, t_min: f64, t_max: f64) !?HitRecord.HitRecord {
        var hit_anything = false;
        var closest_so_far = t_max;
        var result: ?HitRecord.HitRecord = null;

        for (self.objects.items) |obj| {
            const hit_something = obj.hit(r, t_min, closest_so_far);
            if (hit_something) |rec| {
                hit_anything = true;
                closest_so_far = rec.t;
                result = rec;
            }
        }
        if (hit_anything) {
            return result;
        } else {
            return null;
        }
    }
};
