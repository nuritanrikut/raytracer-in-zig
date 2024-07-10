const std = @import("std");
const Dielectric = @import("./dielectric.zig");
const RNG = @import("./rng.zig");
const HitRecord = @import("./hit_record.zig");
const HitableList = @import("./hitable_list.zig");
const Hitable = @import("./hitable.zig");
const Material = @import("./material.zig");
const Lambertian = @import("./lambertian.zig");
const Metal = @import("./metal.zig");
const Vec3 = @import("./vec3.zig");
const Camera = @import("./camera.zig");
const Ray = @import("./ray.zig");
const Sphere = @import("./sphere.zig");

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const Vector3D = @Vector(3, f64);

fn simple_scene(allocator: std.mem.Allocator) !HitableList.HitableList {
    var world = HitableList.HitableList.init(allocator);

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 0.0, -1000.0, 0.0 },
                1000,
                Material.Material{
                    .lambertian = Lambertian.Lambertian.init(Vector3D{ 0.5, 0.5, 0.5 }),
                },
            ),
        },
    );

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 0, 1, 0 },
                1.0,
                Material.Material{
                    .dielectric = Dielectric.Dielectric.init(1.5),
                },
            ),
        },
    );

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ -4, 1, 0 },
                1.0,
                Material.Material{
                    .lambertian = Lambertian.Lambertian.init(
                        Vector3D{ 0.4, 0.2, 0.1 },
                    ),
                },
            ),
        },
    );

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 4, 1, 0 },
                1.0,
                Material.Material{
                    .metal = Metal.Metal.init(Vector3D{ 0.7, 0.6, 0.5 }, 0.0),
                },
            ),
        },
    );

    return world;
}

fn random_scene(allocator: std.mem.Allocator, rng: *RNG.Generator) !HitableList.HitableList {
    var world = HitableList.HitableList.init(allocator);

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 0.0, -1000.0, 0.0 },
                1000,
                Material.Material{
                    .lambertian = Lambertian.Lambertian.init(Vector3D{ 0.5, 0.5, 0.5 }),
                },
            ),
        },
    );

    const world_center = Vector3D{ 4, 0.2, 0 };
    const radius: f64 = 0.2;
    _ = radius;

    var a: f64 = -11;
    while (a < 11) : (a += 1) {
        var b: f64 = -11;
        while (b < 11) : (b += 1) {
            const sphere_center = Vector3D{
                a + 0.9 * rng.random_f64(),
                0.2,
                b + 0.9 * rng.random_f64(),
            };
            if (Vec3.length(Vec3.vec3_sub(sphere_center, world_center)) > 0.9) {
                const choose_mat = rng.random_f64();
                const material = if (choose_mat < 0.8) Material.Material{
                    .lambertian = Lambertian.Lambertian{
                        .albedo = Vec3.random_vec3(rng),
                    },
                } else if (choose_mat < 0.95) Material.Material{
                    .metal = Metal.Metal{
                        .albedo = Vec3.random_vec3(rng),
                        .fuzz = rng.random_range(0, 0.5),
                    },
                } else Material.Material{
                    .dielectric = Dielectric.Dielectric{
                        .ir = 1.5,
                    },
                };

                const sp = Hitable.Hitable{
                    .sphere = try Sphere.Sphere.init(
                        Vector3D{ 0.0, -1000.0, 0.0 },
                        1000,
                        material,
                    ),
                };
                try world.add(sp);
            }
        }
    }

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 0, 1, 0 },
                1.0,
                Material.Material{
                    .dielectric = Dielectric.Dielectric.init(1.5),
                },
            ),
        },
    );

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ -4, 1, 0 },
                1.0,
                Material.Material{
                    .lambertian = Lambertian.Lambertian.init(
                        Vector3D{ 0.4, 0.2, 0.1 },
                    ),
                },
            ),
        },
    );

    try world.add(
        Hitable.Hitable{
            .sphere = try Sphere.Sphere.init(
                Vector3D{ 4, 1, 0 },
                1.0,
                Material.Material{
                    .metal = Metal.Metal.init(Vector3D{ 0.7, 0.6, 0.5 }, 0.0),
                },
            ),
        },
    );

    return world;
}

const Job = struct {
    color: Vector3D,
    rng: RNG.Generator,
    row: usize,
    col: usize,
    world: *HitableList.HitableList,
    cam: Camera.Camera,
    image_width: usize,
    image_height: usize,
    samples_per_pixel_x: usize,
    samples_per_pixel_y: usize,
    max_depth: usize,
};

fn ray_color(col: usize, row: usize, r: *const Ray.Ray, world: *HitableList.HitableList, depth: usize, rng: *RNG.Generator) !Vector3D {
    if (depth == 0)
        return Vector3D{ 1.0, 1.0, 1.0 };

    const infinity = std.math.inf(f64);

    const rec_opt: ?HitRecord.HitRecord = try world.hit(r, 0.001, infinity);
    if (rec_opt) |rec| {
        const did_scatter = rec.material.scatter(r, &rec, rng);
        if (did_scatter) |scatter_result| {
            const attenuation = scatter_result.attenuation;
            const scattered = scatter_result.scattered_ray;
            const recursed_color = try ray_color(col, row, &scattered, world, depth - 1, rng);
            const out = attenuation * recursed_color;
            return out;
        }

        const out = rec.material.diffuse();
        return out;
    }

    const unit_direction: Vector3D = Vec3.unit_vector(r.direction);
    const t: f64 = 0.5 * (unit_direction[1] + 1.0);
    const white: Vector3D = Vector3D{ 1.0, 1.0, 1.0 };
    const blue: Vector3D = Vector3D{ 0.5, 0.7, 1.0 };
    const sky = Vec3.vec3_add(Vec3.vec3_scale(white, (1.0 - t)), Vec3.vec3_scale(blue, t));

    const out = sky;
    return out;
}

fn render_job(job: *Job) !Vector3D {
    var color = Vector3D{ 0, 0, 0 };
    const fsppy: f64 = @floatFromInt(job.samples_per_pixel_y);
    const fsppx: f64 = @floatFromInt(job.samples_per_pixel_x);
    const fh: f64 = @floatFromInt(job.image_height - 1);
    const fw: f64 = @floatFromInt(job.image_width - 1);
    const zsppy: usize = @intCast(job.samples_per_pixel_y);
    const zsppx: usize = @intCast(job.samples_per_pixel_x);

    for (0..zsppy) |sample_y| {
        const fsy: f64 = @floatFromInt(sample_y);
        const y: f64 = fsy / fsppy - 0.5;
        const v: f64 = (@as(f64, @floatFromInt(job.row)) + y) / fh;

        for (0..zsppx) |sample_x| {
            const fsx: f64 = @floatFromInt(sample_x);
            const x: f64 = fsx / fsppx - 0.5;
            const u: f64 = (@as(f64, @floatFromInt(job.col)) + x) / fw;

            var r: Ray.Ray = job.cam.get_ray(&job.rng, u, v);
            const rc = try ray_color(job.col, job.row, &r, job.world, job.max_depth, &job.rng);
            color = Vec3.vec3_add(color, rc);
        }
    }

    return color;
}

fn render(
    image_width: i32,
    image_height: i32,
    jobs: *[]Job,
    pixel: std.ArrayList(std.ArrayList(Vector3D)),
) !void {
    var job_index: i32 = 0;
    const job_count: i32 = image_width * image_height;

    for (jobs.*, 0..) |job, ind| {
        const row: usize = @intCast(job.row);
        const col: usize = @intCast(job.col);

        if (@mod(job_index, image_width) == 0) {
            const remaining_lines = @divFloor((job_count - job_index), image_width);

            try stderr.print(
                "Lines remaining: {}            \r",
                .{remaining_lines},
            );
            // try bwerr.flush();
        }
        const render_result = try render_job(&jobs.*[ind]);
        pixel.items[row].items[col] = render_result;
        job_index += 1;
    }
    try stderr.print("Lines remaining: 0            \r", .{});
    // try bwerr.flush();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    // Image
    const aspect_ratio: f64 = 16.0 / 10.0;
    const image_width: usize = 192 * 2;
    const image_height: usize = @as(usize, @intFromFloat(image_width / aspect_ratio));
    const samples_per_pixel_x: usize = 16;
    const samples_per_pixel_y: usize = 16;
    const max_depth: usize = 50;
    const samples_per_pixel: usize = samples_per_pixel_x * samples_per_pixel_y;

    try stderr.print("Rendering {}x{} image with {}x{} samples per pixel\n", .{ image_width, image_height, samples_per_pixel_x, samples_per_pixel_y });

    // RNG
    var rng = RNG.Generator.init();
    _ = rng.random_f64();

    // World
    var world: ?HitableList.HitableList = null;
    const world_name: []const u8 = args.next() orelse "simple";
    try stderr.print("Loading {s} scene\n", .{world_name});

    if (std.mem.eql(u8, world_name, "simple")) {
        world = try simple_scene(allocator);
    } else {
        world = try random_scene(allocator, &rng);
    }

    // Camera
    const lookfrom = Vector3D{ 13.0, 2.0, 3.0 };
    const lookat = Vector3D{ 0.0, 0.0, 0.0 };
    const vup = Vector3D{ 0.0, 1.0, 0.0 };
    const vfov: f64 = 20.0; // vertical field-of-view in degrees
    const dist_to_focus: f64 = 10.0;
    const aperture: f64 = 0.1;
    const cam = Camera.Camera.init(
        lookfrom,
        lookat,
        vup,
        vfov,
        aspect_ratio,
        aperture,
        dist_to_focus,
    );

    // Render
    const job_count: usize = image_height * image_width;
    const job_index: i32 = 0;
    _ = job_index;

    var jobs: std.ArrayList(Job) = try std.ArrayList(Job).initCapacity(allocator, job_count);
    defer jobs.deinit();

    for (0..image_height) |row| {
        for (0..image_width) |col| {
            try jobs.append(Job{
                .color = Vector3D{ 0, 0, 0 },
                .rng = rng.clone(),
                .row = row,
                .col = col,
                .world = &world.?,
                .cam = cam,
                .image_width = image_width,
                .image_height = image_height,
                .samples_per_pixel_x = samples_per_pixel_x,
                .samples_per_pixel_y = samples_per_pixel_y,
                .max_depth = max_depth,
            });
        }
    }
    try stderr.print("Created {} jobs\n", .{job_count});

    // [row][col]
    var pixels = try std.ArrayList(std.ArrayList(Vector3D)).initCapacity(allocator, image_height);
    defer pixels.deinit();

    for (0..image_height) |_| {
        var row = try std.ArrayList(Vector3D).initCapacity(allocator, image_width);
        row.expandToCapacity();
        try pixels.append(row);
    }

    var j: []Job = try jobs.toOwnedSlice();
    try render(image_width, image_height, &j, pixels);

    try stderr.print("Jobs finished\n", .{});
    try stderr.print("Writing image\n", .{});

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });
    for (0..image_height) |r| {
        const row = image_height - r - 1;
        for (0..image_width) |col| {
            try Vec3.vec3_write_color(stdout, pixels.items[row].items[col], samples_per_pixel);
        }
    }

    try stderr.print("\nDone.\n", .{});
    for (0..image_height) |row| {
        pixels.items[row].deinit();
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
