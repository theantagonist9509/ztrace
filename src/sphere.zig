const std = @import("std");

const vec3_utils = @import("vec3_utils.zig");
const Ray = @import("ray.zig").Ray;

const Color = Vec3;
const Vec3 = vec3_utils.Vec3;

pub const Sphere = struct {
    center: Vec3,
    radius: f32,

    color: Color,

    pub fn hitDist(self: Sphere, ray: Ray) ?f32 {
        const a = vec3_utils.dot(ray.dir, ray.dir); // square function in vec3_utils?
        const half_b = vec3_utils.dot(ray.dir, (ray.origin - self.center));
        const c = vec3_utils.dot(ray.origin - self.center, ray.origin - self.center) - self.radius * self.radius;

        const quarter_discriminant = half_b * half_b - a * c;

        if (quarter_discriminant < 0) return null;

        const ret = -1 * (half_b + std.math.sqrt(quarter_discriminant)) / a; // variable names?
        return if (ret < 0) null else ret;
    }
};
