const HitRecord = @import("./hit_record.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const RNG = @import("./rng.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const metal_t = struct {
    albedo: Vector3D,
    fuzz: f64,

    pub fn init(albedo: Vector3D, fuzz: f64) @This() {
        var result = .{
            .albedo = albedo,
            .fuzz = if (fuzz < 1.0) fuzz else 1.0,
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
        const reflected = Vec3.reflect(Vec3.unit_vector(r_in.direction), rec.normal);
        const scatter_direction = Vec3.vec3_add(reflected, Vec3.vec3_scale(Vec3.random_in_unit_sphere(rng), self.fuzz));

        if (Vec3.vec3_dot(scatter_direction, rec.normal) > 0) {
            return Material.scatter_result_t{
                .attenuation = self.albedo,
                .scattered_ray = Ray.ray_t{ .origin = rec.p, .direction = scatter_direction },
            };
        } else {
            return null;
        }
    }
};
