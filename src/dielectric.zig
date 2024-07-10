const std = @import("std");

const HitRecord = @import("./hit_record.zig");
const Material = @import("./material.zig");
const Ray = @import("./ray.zig");
const RNG = @import("./rng.zig");
const Vec3 = @import("./vec3.zig");

const Vector3D = @Vector(3, f64);

pub const Dielectric = struct {
    ir: f64, // Index of Refraction

    pub fn init(ir: f64) @This() {
        const result = .{
            .ir = ir,
        };
        return result;
    }

    pub fn diffuse(self: @This()) Vector3D {
        _ = self;
        return Vector3D{ 1.0, 1.0, 1.0 };
    }

    pub fn scatter(
        self: @This(),
        r_in: *const Ray.Ray,
        rec: *const HitRecord.HitRecord,
        rng: *RNG.Generator,
    ) ?Material.ScatterResult {
        const refraction_ratio = if (rec.front_face) 1.0 / self.ir else self.ir;
        const unit_direction = Vec3.unit_vector(r_in.direction);
        const d = Vec3.vec3_dot(Vec3.vec3_neg(unit_direction), rec.normal);
        const cos_theta = @min(d, 1.0);
        const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = refraction_ratio * sin_theta > 1.0;
        const t = rng.random_f64();
        const refl = reflectance(cos_theta, refraction_ratio);
        const should_reflect = refl > t;

        const direction = if (cannot_refract or should_reflect) Vec3.reflect(unit_direction, rec.normal) else Vec3.refract(unit_direction, rec.normal, refraction_ratio);

        const result = Material.ScatterResult{
            .attenuation = Vector3D{ 1.0, 1.0, 1.0 },
            .scattered_ray = Ray.Ray{
                .origin = rec.p,
                .direction = direction,
            },
        };
        return result;
    }

    fn reflectance(cosine: f64, ref_idx: f64) f64 {
        // Use Schlick's approximation for reflectance.
        var r0 = (1.0 - ref_idx) / (1.0 + ref_idx);
        r0 = r0 * r0;
        return r0 + (1.0 - r0) * std.math.pow(f64, (1.0 - cosine), 5.0);
    }
};
