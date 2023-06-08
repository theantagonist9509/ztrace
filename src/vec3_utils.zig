const std = @import("std");

pub const Vec3 = @Vector(3, f32);

pub fn dot(a: Vec3, b: Vec3) f32 {
    return @reduce(.Add, a * b);
}

pub fn unit(a: Vec3) Vec3 {
    return a / @splat(3, std.math.sqrt(@reduce(.Add, a * a)));
}
