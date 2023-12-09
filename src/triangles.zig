const std = @import("std");

const vector3_utilities = @import("vector3_utilities.zig");
const Material = @import("material.zig").Material;
const Ray = @import("ray.zig").Ray;
const TypeId = @import("typeid.zig").TypeId;

const Vector3 = vector3_utilities.Vector3;

pub const Triangles = struct {
    pub const Geometry = struct {
        vertex_array: [3]Vector3, // vertices?
        normal: Vector3,

        pub inline fn hitDistance(self: Geometry, ray: Ray) f32 {
            const distance = vector3_utilities.dot(self.normal, self.vertex_array[0] - ray.origin) / vector3_utilities.dot(self.normal, ray.direction);

            return if (distance > 0 and self.isInside(ray.coordinates(distance))) (distance) else (std.math.floatMax(f32));
        }

        inline fn isInside(self: Geometry, point: Vector3) bool {
            var is_inside = true;
            inline for (0..3) |i| {
                const one = self.vertex_array[(i + 1) % 3] - self.vertex_array[i]; // names?
                const two = self.vertex_array[(i + 2) % 3] - self.vertex_array[i];
                is_inside = is_inside and (vector3_utilities.dot(point - self.vertex_array[i], two - @as(Vector3, @splat(vector3_utilities.dot(one, two) / vector3_utilities.square(one))) * one) > 0);
            }
            return is_inside;
        }

        pub inline fn getNormal(self: Geometry, coordinates: Vector3) Vector3 {
            _ = coordinates;
            return self.normal;
        }

        pub inline fn updateNormal(self: *Geometry) void {
            self.normal = vector3_utilities.unit(vector3_utilities.cross(self.vertex_array[1] - self.vertex_array[0], self.vertex_array[2] - self.vertex_array[1]));
        }
    };

    type_id: TypeId = .triangles,

    geometries: []Geometry,
    materials: []Material,
};
