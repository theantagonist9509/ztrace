const std = @import("std");

const vec3_utils = @import("vec3_utils.zig");
const Ppm = @import("ppm.zig").Ppm;
const Ray = @import("ray.zig").Ray;

const Vec3 = vec3_utils.Vec3;

pub const Camera = struct {
    pos: Vec3, // variable name?
    pitch: f32,
    yaw: f32,
    viewport_width: f32,
    fov: f32,
    image: Ppm,
    gamma: f32,

    pub fn ray(self: Camera, pixel_index: usize) Ray { // variable names?
        const pixel_index_x = @intCast(isize, pixel_index % self.image.width) - @intCast(isize, self.image.width / 2);
        const pixel_index_y = @intCast(isize, self.image.height / 2) - @intCast(isize, pixel_index / self.image.width);

        const pixel_x = @intToFloat(f32, pixel_index_x) * (self.viewport_width / @intToFloat(f32, self.image.width)); // brackets?
        const pixel_y = @intToFloat(f32, pixel_index_y) * (self.viewport_width / @intToFloat(f32, self.image.width));

        const pitch = std.math.degreesToRadians(f32, self.pitch);
        const yaw = std.math.degreesToRadians(f32, self.yaw);
        const fov = std.math.degreesToRadians(f32, self.fov);

        const viewport_x_hat = Vec3{
            std.math.cos(yaw),
            0,
            std.math.sin(yaw),
        };
        const viewport_y_hat = Vec3{
            -1 * std.math.sin(pitch) * std.math.sin(yaw),
            std.math.cos(pitch),
            std.math.sin(pitch) * std.math.cos(yaw),
        };
        const relative_pixel_pos = @splat(3, pixel_x) * viewport_x_hat + @splat(3, pixel_y) * viewport_y_hat;

        const relative_origin_pos = @splat(3, self.viewport_width / (2 * std.math.tan(fov / 2))) * Vec3{ // relative_oculus_pos? pos vs coords? implement as cross product?
            -1 * std.math.sin(yaw) * std.math.cos(pitch),
            -1 * std.math.sin(pitch),
            std.math.cos(yaw) * std.math.cos(pitch),
        };

        return Ray{
            .origin = self.pos + relative_origin_pos,
            .dir = vec3_utils.unit(relative_pixel_pos - relative_origin_pos),
        };
    }
};
