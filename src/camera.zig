const std = @import("std");

const vector3_utilities = @import("vector3_utilities.zig");
const Pixmap = @import("pixmap.zig").Pixmap;
const Ray = @import("ray.zig").Ray;

const Vector3 = vector3_utilities.Vector3;

pub const Camera = struct {
    viewport_center_coordinates: Vector3,
    viewport_width: f32,
    viewport_x_hat: Vector3,
    viewport_y_hat: Vector3,
    relative_focus_coordinates: Vector3, // drop 'coordinates'? focus_relative_coordinates? focus_coordinates_relative? wrt viewport's center

    pub fn ray(self: Camera, image: Pixmap(u8), random: std.rand.Random, pixel_index: usize) Ray {
        // adding random (-0.5, 0.5) for anti-aliasing
        const pixel_index_x = @as(f32, @floatFromInt(pixel_index % image.width)) - @as(f32, @floatFromInt(image.width)) / 2 + random.float(f32) - 0.5;
        const pixel_index_y = @as(f32, @floatFromInt(image.height)) / 2 - @as(f32, @floatFromInt(pixel_index / image.width)) + random.float(f32) - 0.5;

        const pixel_x = pixel_index_x * self.viewport_width / @as(f32, @floatFromInt(image.width));
        const pixel_y = pixel_index_y * self.viewport_width / @as(f32, @floatFromInt(image.width));

        const relative_pixel_coordinates = @as(Vector3, @splat(pixel_x)) * self.viewport_x_hat + @as(Vector3, @splat(pixel_y)) * self.viewport_y_hat;

        return Ray{
            .origin = self.viewport_center_coordinates + self.relative_focus_coordinates,
            .direction = vector3_utilities.unit(relative_pixel_coordinates - self.relative_focus_coordinates),
        };
    }
};
