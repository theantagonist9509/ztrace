const vec3_utils = @import("vec3_utils.zig");

const Vec3 = vec3_utils.Vec3;

pub const Ray = struct {
    origin: Vec3,
    dir: Vec3,

    pub fn coords(self: Ray, dist: f32) Vec3 { // pos?
        return self.origin + @splat(3, dist) * self.dir;
    }
};
