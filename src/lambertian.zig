const HitRecord = @import("./hit_record.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const RNG = @import("./rng.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const Lambertian = struct {
    albedo: Vector3D,

    pub fn init(albedo: Vector3D) @This() {
        const result = .{
            .albedo = albedo,
        };
        return result;
    }

    pub fn diffuse(self: @This()) Vector3D {
        return self.albedo;
    }

    pub fn scatter(
        self: @This(),
        r_in: *const Ray.Ray,
        rec: *const HitRecord.HitRecord,
        rng: *RNG.Generator,
    ) ?Material.ScatterResult {
        _ = r_in;
        var scatter_direction = Vec3.vec3_add(rec.normal, Vec3.random_unit_vector(rng));

        // Catch degenerate scatter direction
        if (Vec3.near_zero(scatter_direction))
            scatter_direction = rec.normal;

        const result = Material.ScatterResult{
            .attenuation = self.albedo,
            .scattered_ray = Ray.Ray{ .origin = rec.p, .direction = scatter_direction },
        };
        return result;
    }
};
