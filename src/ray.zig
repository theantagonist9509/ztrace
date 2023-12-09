const std = @import("std");

const TypeId = @import("typeid.zig").TypeId;
const Vector3 = @import("vector3_utilities.zig").Vector3;

pub const Ray = struct {
    pub const hit_distance_epsilon = 1.0 / @as(comptime_float, 1 << 6); // std.math.pow not implemented for comptime_float :(
    pub const hit_directness_epsilon = 1.0 / @as(comptime_float, 1 << 6); // std.math.pow not implemented for comptime_float :(

    origin: Vector3,
    direction: Vector3,

    pub inline fn coordinates(self: Ray, distance: f32) Vector3 {
        return self.origin + @as(Vector3, @splat(distance)) * self.direction;
    }

    pub inline fn getClosestObjectData(objects_tuple: anytype, ray: Ray) struct {
        parent_type_id: TypeId,
        index: usize,
        distance: f32,
    } { // check for validity of anytype?
        var closest_object_parent_type_id: TypeId = undefined;
        var closest_object_index: usize = undefined;
        var closest_object_distance = std.math.floatMax(f32);

        inline for (objects_tuple) |objects| {
            for (objects.geometries, 0..) |geometry, geometry_index| {
                const distance = geometry.hitDistance(ray);
                if (distance > Ray.hit_distance_epsilon and distance < closest_object_distance) {
                    closest_object_parent_type_id = objects.type_id;
                    closest_object_index = geometry_index;
                    closest_object_distance = distance;
                }
            }
        }

        if (closest_object_distance == std.math.floatMax(f32)) {
            return .{
                .parent_type_id = undefined,
                .index = undefined,
                .distance = std.math.floatMax(f32),
            };
        }

        return .{
            .parent_type_id = closest_object_parent_type_id,
            .index = closest_object_index,
            .distance = closest_object_distance,
        };
    }
};
