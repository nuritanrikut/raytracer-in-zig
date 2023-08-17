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

pub const scatter_result_t = struct {
    attenuation: Vector3D,
    scattered_ray: Ray.ray_t,
};

pub const material_t = union(enum) {
    dummy: struct {
        fn diffuse(self: *const @This()) Vector3D {
            _ = self;
            return Vector3D{ 0, 0, 0 };
        }

        fn scatter(
            self: *const @This(),
            r_in: Ray.ray_t,
            rec: HitRecord.hit_record_t,
            rng: *RNG.random_number_generator_t,
        ) ?scatter_result_t {
            _ = rng;
            _ = rec;
            _ = r_in;
            _ = self;
            return null;
        }
    },
    lambertian: Lambertian.lambertian_t,
    metal: Metal.metal_t,
    dielectric: Dielectric.dielectric_t,

    pub fn init() material_t {
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
        r_in: Ray.ray_t,
        rec: HitRecord.hit_record_t,
        rng: *RNG.random_number_generator_t,
    ) ?scatter_result_t {
        return switch (self) {
            .dielectric => |mat| mat.scatter(r_in, rec, rng),
            .lambertian => |mat| mat.scatter(r_in, rec, rng),
            .metal => |mat| mat.scatter(r_in, rec, rng),
            else => null,
        };
    }
};
