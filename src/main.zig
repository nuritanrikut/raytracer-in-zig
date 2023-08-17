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

const Vector3D = @Vector(3, f64);

fn simple_scene(allocator: std.mem.Allocator) !HitableList.HitableList {
    var world = HitableList.HitableList.init(allocator);

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 0.0, -1000.0, 0.0 },
                1000,
                Material.material_t{
                    .lambertian = Lambertian.lambertian_t.init(Vector3D{ 0.5, 0.5, 0.5 }),
                },
            ),
        },
    );

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 0, 1, 0 },
                1.0,
                Material.material_t{
                    .dielectric = Dielectric.dielectric_t.init(1.5),
                },
            ),
        },
    );

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ -4, 1, 0 },
                1.0,
                Material.material_t{
                    .lambertian = Lambertian.lambertian_t.init(
                        Vector3D{ 0.4, 0.2, 0.1 },
                    ),
                },
            ),
        },
    );

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 4, 1, 0 },
                1.0,
                Material.material_t{
                    .metal = Metal.metal_t.init(Vector3D{ 0.7, 0.6, 0.5 }, 0.0),
                },
            ),
        },
    );

    return world;
}

fn random_scene(allocator: std.mem.Allocator, rng: *RNG.random_number_generator_t) !HitableList.HitableList {
    var world = HitableList.HitableList.init(allocator);

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 0.0, -1000.0, 0.0 },
                1000,
                Material.material_t{
                    .lambertian = Lambertian.lambertian_t.init(Vector3D{ 0.5, 0.5, 0.5 }),
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
                const material = if (choose_mat < 0.8) Material.material_t{
                    .lambertian = Lambertian.lambertian_t{
                        .albedo = Vec3.random_vec3(rng),
                    },
                } else if (choose_mat < 0.95) Material.material_t{
                    .metal = Metal.metal_t{
                        .albedo = Vec3.random_vec3(rng),
                        .fuzz = rng.random_range(0, 0.5),
                    },
                } else Material.material_t{
                    .dielectric = Dielectric.dielectric_t{
                        .ir = 1.5,
                    },
                };

                const sp = Hitable.hitable_t{
                    .sphere = try Sphere.sphere_t.init(
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
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 0, 1, 0 },
                1.0,
                Material.material_t{
                    .dielectric = Dielectric.dielectric_t.init(1.5),
                },
            ),
        },
    );

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ -4, 1, 0 },
                1.0,
                Material.material_t{
                    .lambertian = Lambertian.lambertian_t.init(
                        Vector3D{ 0.4, 0.2, 0.1 },
                    ),
                },
            ),
        },
    );

    try world.add(
        Hitable.hitable_t{
            .sphere = try Sphere.sphere_t.init(
                Vector3D{ 4, 1, 0 },
                1.0,
                Material.material_t{
                    .metal = Metal.metal_t.init(Vector3D{ 0.7, 0.6, 0.5 }, 0.0),
                },
            ),
        },
    );

    return world;
}

const Job = struct {
    color: Vector3D,
    rng: RNG.random_number_generator_t,
    row: i32,
    col: i32,
    world: HitableList.HitableList,
    cam: Camera.camera_t,
    image_width: i32,
    image_height: i32,
    samples_per_pixel_x: i32,
    samples_per_pixel_y: i32,
    max_depth: i32,
};

fn ray_color(col: i32, row: i32, r: Ray.ray_t, world: HitableList.HitableList, depth: i32, rng: *RNG.random_number_generator_t) !Vector3D {
    if (depth <= 0)
        return Vector3D{ 1.0, 1.0, 1.0 };

    // const stderr_file = std.io.getStdErr().writer();
    // var bwerr = std.io.bufferedWriter(stderr_file);
    // const stderr = bwerr.writer();

    const infinity = std.math.inf(f64);

    var rec_opt: ?HitRecord.hit_record_t = try world.hit(r, 0.001, infinity);
    if (rec_opt) |rec| {
        const did_scatter = rec.material.scatter(r, rec, rng);
        if (did_scatter) |scatter_result| {
            const attenuation = scatter_result.attenuation;
            const scattered = scatter_result.scattered_ray;
            var recursed_color = try ray_color(col, row, scattered, world, depth - 1, rng);
            const out = attenuation * recursed_color;
            // try stderr.print(
            //     "> Scatter {d} {d} dir=({d:.4}, {d:.4}, {d:.4}) attenuation=({d:.4}, {d:.4}, {d:.4}) recursed_color=({d:.4}, {d:.4}, {d:.4}) out=({d:.4}, {d:.4}, {d:.4})\n",
            //     .{ col, row, r.direction[0], r.direction[1], r.direction[2], attenuation[0], attenuation[1], attenuation[2], recursed_color[0], recursed_color[1], recursed_color[2], out[0], out[1], out[2] },
            // );
            // try bwerr.flush();
            return out;
        }

        const out = rec.material.diffuse();
        // try stderr.print(
        //     "> Diffuse {d} {d} out=({d:.4}, {d:.4}, {d:.4})\n",
        //     .{ col, row, out[0], out[1], out[2] },
        // );
        // try bwerr.flush();
        return out;
    }

    const unit_direction: Vector3D = Vec3.unit_vector(r.direction);
    const t: f64 = 0.5 * (unit_direction[1] + 1.0);
    const white: Vector3D = Vector3D{ 1.0, 1.0, 1.0 };
    const blue: Vector3D = Vector3D{ 0.5, 0.7, 1.0 };
    const sky = Vec3.vec3_add(Vec3.vec3_scale(white, (1.0 - t)), Vec3.vec3_scale(blue, t));

    const out = sky;
    // try stderr.print(
    //     "> Sky {d} {d} {d} dir=({d:.4}, {d:.4}, {d:.4}) out=({d:.4}, {d:.4}, {d:.4})\n",
    //     .{ col, row, t, r.direction[0], r.direction[1], r.direction[2], out[0], out[1], out[2] },
    // );
    // try bwerr.flush();
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

    // const stderr_file = std.io.getStdErr().writer();
    // var bwerr = std.io.bufferedWriter(stderr_file);
    // const stderr = bwerr.writer();

    for (0..zsppy) |sample_y| {
        const fsy: f64 = @floatFromInt(sample_y);
        const y: f64 = fsy / fsppy - 0.5;
        const v: f64 = (@as(f64, @floatFromInt(job.row)) + y) / fh;

        for (0..zsppx) |sample_x| {
            const fsx: f64 = @floatFromInt(sample_x);
            const x: f64 = fsx / fsppx - 0.5;
            const u: f64 = (@as(f64, @floatFromInt(job.col)) + x) / fw;

            var r: Ray.ray_t = job.cam.get_ray(&job.rng, u, v);
            const rc = try ray_color(job.col, job.row, r, job.world, job.max_depth, &job.rng);
            color = Vec3.vec3_add(color, rc);

            // try stderr.print(
            //     "> Job {d} {d}, sample {d} {d}, rc=({d:.4} {d:.4} {d:.4})\n",
            //     .{ job.col, job.row, sample_x, sample_y, rc[0], rc[1], rc[2] },
            // );
            // try bwerr.flush();
        }
    }

    return color;
}

fn render(
    image_width: i32,
    image_height: i32,
    jobs: []Job,
    pixel: std.ArrayList(std.ArrayList(Vector3D)),
) !void {
    const stderr_file = std.io.getStdErr().writer();
    var bwerr = std.io.bufferedWriter(stderr_file);
    const stderr = bwerr.writer();
    var job_index: i32 = 0;
    const job_count: i32 = image_width * image_height;

    for (jobs, 0..) |job, ind| {
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
        const render_result = try render_job(&jobs[ind]);
        pixel.items[row].items[col] = render_result;
        job_index += 1;
    }
    try stderr.print("Lines remaining: 0            \r", .{});
    // try bwerr.flush();
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    const stdout_file = std.io.getStdOut().writer();
    var bwout = std.io.bufferedWriter(stdout_file);
    const stdout = bwout.writer();
    const stderr_file = std.io.getStdErr().writer();
    var bwerr = std.io.bufferedWriter(stderr_file);
    const stderr = bwerr.writer();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next();

    // Image
    const aspect_ratio: f64 = 16.0 / 10.0;
    const image_width: i32 = 192 * 2;
    const image_height: i32 = @as(i32, image_width / aspect_ratio);
    const samples_per_pixel_x: i32 = 16;
    const samples_per_pixel_y: i32 = 16;
    const max_depth: i32 = 50;
    const samples_per_pixel: i32 = samples_per_pixel_x * samples_per_pixel_y;

    try stderr.print("Rendering {}x{} image with {}x{} samples per pixel\n", .{ image_width, image_height, samples_per_pixel_x, samples_per_pixel_y });
    // try bwerr.flush();

    // RNG
    var rng = RNG.random_number_generator_t.init();
    _ = rng.random_f64();

    // World
    var world: ?HitableList.HitableList = null;
    var world_name: []const u8 = args.next() orelse "simple";
    try stderr.print("Loading {s} scene\n", .{world_name});
    // try bwerr.flush();

    if (std.mem.eql(u8, world_name, "simple")) {
        world = try simple_scene(allocator);
    } else {
        world = try random_scene(allocator, &rng);
    }
    // try bwerr.flush();

    // Camera
    var lookfrom = Vector3D{ 13.0, 2.0, 3.0 };
    var lookat = Vector3D{ 0.0, 0.0, 0.0 };
    var vup = Vector3D{ 0.0, 1.0, 0.0 };
    var vfov: f64 = 20.0; // vertical field-of-view in degrees
    var dist_to_focus: f64 = 10.0;
    var aperture: f64 = 0.1;
    var cam = Camera.camera_t.init(
        lookfrom,
        lookat,
        vup,
        vfov,
        aspect_ratio,
        aperture,
        dist_to_focus,
    );

    // Render
    var job_count: usize = image_height * image_width;
    var job_index: i32 = 0;
    _ = job_index;

    var jobs: std.ArrayList(Job) = try std.ArrayList(Job).initCapacity(allocator, job_count);
    defer jobs.deinit();

    for (0..image_height) |row| {
        for (0..image_width) |col| {
            try jobs.append(Job{
                .color = Vector3D{ 0, 0, 0 },
                .rng = rng.clone(),
                .row = @intCast(row),
                .col = @intCast(col),
                .world = world.?,
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
    // try bwerr.flush();

    // [row][col]
    var pixels = try std.ArrayList(std.ArrayList(Vector3D)).initCapacity(allocator, image_height);
    defer pixels.deinit();

    for (0..image_height) |_| {
        var row = try std.ArrayList(Vector3D).initCapacity(allocator, image_width);
        row.expandToCapacity();
        try pixels.append(row);
    }

    var j: []Job = try jobs.toOwnedSlice();
    try render(image_width, image_height, j, pixels);

    try stderr.print("Jobs finished\n", .{});
    try stderr.print("Writing image\n", .{});
    // try bwerr.flush();

    try stdout.print("P3\n{} {}\n255\n", .{ image_width, image_height });
    // try bwout.flush();
    for (0..image_height) |r| {
        const row = image_height - r - 1;
        for (0..image_width) |col| {
            try Vec3.vec3_write_color(stdout, pixels.items[row].items[col], samples_per_pixel);
        }
        // try bwout.flush();
    }

    try stderr.print("\nDone.\n", .{});
    // try bwerr.flush();
    for (0..image_height) |row| {
        pixels.items[row].deinit();
    }

    try bwout.flush(); // don't forget to flush!
    try bwerr.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
