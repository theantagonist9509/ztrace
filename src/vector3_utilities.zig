// USE ARRAY INSTEAD OF VECTOR? (NO PADDING MEMORY NEEDED)

const std = @import("std");

pub const Vector3 = @Vector(3, f32); // importing Vector3 vs @Vector(3, f32)? defining Color?

pub inline fn dot(a: Vector3, b: Vector3) f32 {
    return @reduce(.Add, a * b);
}

pub inline fn square(a: Vector3) f32 {
    return dot(a, a);
}

pub inline fn unit(a: Vector3) Vector3 {
    return a / @as(Vector3, @splat(@sqrt(square(a))));
}

pub inline fn cross(a: Vector3, b: Vector3) Vector3 {
    var ret: Vector3 = undefined;
    inline for (0..3) |i| {
        ret[i] = a[(i + 1) % 3] * b[(i + 2) % 3] - b[(i + 1) % 3] * a[(i + 2) % 3];
    }
    return ret;
}

pub inline fn randomUnit(random: std.rand.Random) Vector3 {
    while (true) {
        var a: Vector3 = undefined;
        inline for (0..3) |i| {
            a[i] = 2 * random.float(f32) - 1;
        }
        if (square(a) < 1) {
            return unit(a);
        }
    }
}

pub fn transformBasisVectors(yaw: f32, pitch: f32) [3]Vector3 { // inline? (check everywhere)
    const sin_yaw = @sin(yaw);
    const cos_yaw = @cos(yaw);
    const sin_pitch = @sin(pitch);
    const cos_pitch = @cos(pitch);

    return .{
        .{
            cos_yaw,
            0,
            -sin_yaw,
        },
        .{
            sin_pitch * sin_yaw,
            cos_pitch,
            sin_pitch * cos_yaw,
        },
        .{
            cos_pitch * sin_yaw,
            -sin_pitch,
            cos_pitch * cos_yaw,
        },
    };
}
