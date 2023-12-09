const std = @import("std");

const vector3_utilities = @import("vector3_utilities.zig");
const Material = @import("material.zig").Material;
const Ray = @import("ray.zig").Ray;
const TypeId = @import("typeid.zig").TypeId;

const Vector3 = vector3_utilities.Vector3;

pub const Planes = struct {
    pub const Geometry = struct {
        reference_point: Vector3,
        normal: Vector3,

        pub inline fn hitDistance(self: Geometry, ray: Ray) f32 {
            const distance = vector3_utilities.dot(self.normal, self.reference_point - ray.origin) / vector3_utilities.dot(self.normal, ray.direction);
            return if (distance < 0) (std.math.floatMax(f32)) else (distance);
        }

        pub inline fn getNormal(self: Geometry, coordinates: Vector3) Vector3 { // need this function? just return the normal field where needed?
            _ = coordinates;
            return self.normal;
        }
    };

    type_id: TypeId = .planes,

    geometries: []Geometry,
    materials: []Material,
};
