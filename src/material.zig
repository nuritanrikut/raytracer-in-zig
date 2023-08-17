const std = @import("std");
const HitRecord = @import("./hit_record.zig");
const Ray = @import("./ray.zig");
const RNG = @import("./rng.zig");
const Vec3 = @import("./vec3.zig");
const Dielectric = @import("./dielectric.zig");
const HitableList = @import("./hitable_list.zig");
const Hitable = @import("./hitable.zig");
const Lambertian = @import("./lambertian.zig");
const Metal = @import("./metal.zig");
const Camera = @import("./camera.zig");
const Sphere = @import("./sphere.zig");

const Vector3D = @Vector(3, f64);

pub const ScatterResult = struct {
    attenuation: Vector3D,
    scattered_ray: Ray.Ray,
};

pub const Material = union(enum) {
    dummy: struct {
        fn diffuse(self: *const @This()) Vector3D {
            _ = self;
            return Vector3D{ 0, 0, 0 };
        }

        fn scatter(
            self: *const @This(),
            r_in: Ray.Ray,
            rec: HitRecord.HitRecord,
            rng: *RNG.Generator,
        ) ?ScatterResult {
            _ = rng;
            _ = rec;
            _ = r_in;
            _ = self;
            return null;
        }
    },
    lambertian: Lambertian.Lambertian,
    metal: Metal.Metal,
    dielectric: Dielectric.Dielectric,

    pub fn init() Material {
        return .dummy;
    }

    pub fn diffuse(self: @This()) Vector3D {
        return switch (self) {
            .dielectric => |mat| mat.diffuse(),
            .lambertian => |mat| mat.diffuse(),
            .metal => |mat| mat.diffuse(),
            .dummy => |mat| mat.diffuse(),
        };
    }

    pub fn scatter(
        self: @This(),
        r_in: Ray.Ray,
        rec: HitRecord.HitRecord,
        rng: *RNG.Generator,
    ) ?ScatterResult {
        return switch (self) {
            .dielectric => |mat| mat.scatter(r_in, rec, rng),
            .lambertian => |mat| mat.scatter(r_in, rec, rng),
            .metal => |mat| mat.scatter(r_in, rec, rng),
            else => null,
        };
    }
};
