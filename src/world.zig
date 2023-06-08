const std = @import("std");

const vec3_utils = @import("vec3_utils.zig");
const Camera = @import("camera.zig").Camera;
const Sphere = @import("sphere.zig").Sphere;

const Color = Vec3;
const Vec3 = vec3_utils.Vec3;

pub const World = struct {
    spheres: []const Sphere,
    camera: Camera,
    sky_color: Color,

    pub fn initFromJson(allocator: std.mem.Allocator, sub_path: []const u8) !World {
        const file = try std.fs.cwd().openFile(sub_path, .{});
        defer file.close();
        var string = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        var world = try std.json.parseFromSlice(World, allocator, string, .{});
        world.camera.image.data = try allocator.alloc(u8, 3 * world.camera.image.width * world.camera.image.height);
        return world;
    }

    pub fn raytrace(self: *World, allocator: std.mem.Allocator, num_threads: usize, max_depth: u32) !void {
        const child_threads = try allocator.alloc(std.Thread, num_threads - 1);
        for (child_threads, 0..) |*thread, i| thread.* = try std.Thread.spawn(.{}, raytraceThunk, .{
            self,
            num_threads,
            i,
            max_depth,
        });
        raytraceThunk(self, num_threads, num_threads - 1, max_depth);
        for (child_threads) |thread| thread.join();
    }

    fn raytraceThunk(self: *World, num_threads: usize, thread_idx: usize, max_depth: u32) void {
        var i: usize = thread_idx;
        while (i < self.camera.image.data.len / 3) : (i += num_threads) {
            var depth: u32 = 1;
            var color = self.sky_color;
            var current_ray = self.camera.ray(i);
            while (true) {
                var nearest_dist = std.math.floatMax(f32);
                var nearest_sphere: *const Sphere = undefined;
                for (self.spheres) |*sphere| { // propose |*const sphere|, make references to captures like |sphere| give errors as it is unknown whether they are passed by value or reference
                    if (sphere.hitDist(current_ray)) |dist| {
                        if (dist < nearest_dist) {
                            nearest_dist = dist;
                            nearest_sphere = sphere;
                        }
                    }
                }
                if (nearest_dist == std.math.floatMax(f32)) {
                    break;
                }
                color *= nearest_sphere.color;
                if (depth == max_depth) {
                    break;
                }
                depth += 1;
                const hit_coords = current_ray.coords(nearest_dist);
                const normal = (hit_coords - nearest_sphere.center) / @splat(3, nearest_sphere.radius);

                color *= @splat(3, std.math.clamp(-1 * vec3_utils.dot(current_ray.dir, normal), 0, 1));

                current_ray = .{
                    .origin = hit_coords,
                    .dir = current_ray.dir - @splat(3, 2 * vec3_utils.dot(current_ray.dir, normal)) * normal,
                };
            }
            color[0] = std.math.pow(f32, color[0], 1 / self.camera.gamma);
            color[1] = std.math.pow(f32, color[1], 1 / self.camera.gamma);
            color[2] = std.math.pow(f32, color[2], 1 / self.camera.gamma);
            self.camera.image.data[3 * i] = @floatToInt(u8, color[0] * 255);
            self.camera.image.data[3 * i + 1] = @floatToInt(u8, color[1] * 255);
            self.camera.image.data[3 * i + 2] = @floatToInt(u8, color[2] * 255);
        }
    }
};
