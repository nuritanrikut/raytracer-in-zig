const std = @import("std");
const HitRecord = @import("./hit_record.zig");
const Hitable = @import("./hitable.zig");
const Ray = @import("./ray.zig");

pub const HitableList = struct {
    objects: std.ArrayList(Hitable.hitable_t),

    pub fn init(allocator: std.mem.Allocator) HitableList {
        return HitableList{
            .objects = std.ArrayList(Hitable.hitable_t).init(allocator),
        };
    }

    pub fn deinit(self: *HitableList) void {
        self.objects.deinit();
    }

    pub fn add(self: *HitableList, obj: Hitable.hitable_t) !void {
        try self.objects.append(obj);
    }

    pub fn hit(self: HitableList, r: Ray.ray_t, t_min: f64, t_max: f64) !?HitRecord.hit_record_t {
        var hit_anything = false;
        var closest_so_far = t_max;
        var result: ?HitRecord.hit_record_t = null;

        // const stderr_file = std.io.getStdErr().writer();
        // var bwerr = std.io.bufferedWriter(stderr_file);
        // const stderr = bwerr.writer();

        for (self.objects.items) |obj| {
            // try stderr.print(
            //     "!!! checking obj\n",
            //     .{},
            // );
            // try bwerr.flush();

            const hit_something = try obj.hit(r, t_min, closest_so_far);
            if (hit_something) |rec| {
                hit_anything = true;
                closest_so_far = rec.t;
                result = rec;

                // try stderr.print(
                //     "!!! hit_something\n",
                //     .{},
                // );
                // try bwerr.flush();
            }
        }
        if (hit_anything) {
            return result;
        } else {
            return null;
        }
    }
};
