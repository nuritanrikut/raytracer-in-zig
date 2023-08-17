const HitRecord = @import("./hit_record.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const RNG = @import("./rng.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const lambertian_t = struct {
    albedo: Vector3D,

    pub fn init(albedo: Vector3D) @This() {
        var result = .{
            .albedo = albedo,
        };
        return result;
    }

    pub fn diffuse(self: @This()) Vector3D {
        return self.albedo;
    }

    pub fn scatter(
        self: @This(),
        r_in: Ray.ray_t,
        rec: HitRecord.hit_record_t,
        rng: *RNG.random_number_generator_t,
    ) ?Material.scatter_result_t {
        _ = r_in;
        var scatter_direction = Vec3.vec3_add(rec.normal, Vec3.random_unit_vector(rng));

        // Catch degenerate scatter direction
        if (Vec3.near_zero(scatter_direction))
            scatter_direction = rec.normal;

        const result = Material.scatter_result_t{
            .attenuation = self.albedo,
            .scattered_ray = Ray.ray_t{ .origin = rec.p, .direction = scatter_direction },
        };
        return result;
    }
};
