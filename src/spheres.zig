const std = @import("std");

const vector3_utilities = @import("vector3_utilities.zig");
const Material = @import("material.zig").Material;
const Ray = @import("ray.zig").Ray;
const TypeId = @import("typeid.zig").TypeId;

const Vector3 = vector3_utilities.Vector3;

pub const Spheres = struct {
    pub const Geometry = struct {
        center: Vector3,
        radius: f32,

        pub inline fn hitDistance(self: Geometry, ray: Ray) f32 {
            const a = vector3_utilities.square(ray.direction);
            const half_b = vector3_utilities.dot(ray.direction, (ray.origin - self.center));
            const c = vector3_utilities.square(ray.origin - self.center) - self.radius * self.radius;

            const quarter_discriminant = half_b * half_b - a * c;

            if (quarter_discriminant < 0) return std.math.floatMax(f32);

            const distance = -1 * (half_b + std.math.sqrt(quarter_discriminant)) / a;
            return if (distance < 0) std.math.floatMax(f32) else distance;
        }

        pub inline fn getNormal(self: Geometry, coordinates: Vector3) Vector3 {
            return (coordinates - self.center) / @as(Vector3, @splat(self.radius));
        }
    };

    type_id: TypeId = .spheres,

    geometries: []Geometry,
    materials: []Material,
};
