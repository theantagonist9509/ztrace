const std = @import("std");

const vector3_utilities = @import("vector3_utilities.zig");
const Camera = @import("camera.zig").Camera;
const Material = @import("material.zig").Material;
const Pixmap = @import("pixmap.zig").Pixmap;
const Planes = @import("planes.zig").Planes;
const Ray = @import("ray.zig").Ray;
const Spheres = @import("spheres.zig").Spheres;
const Triangles = @import("triangles.zig").Triangles;
const TypeId = @import("typeid.zig").TypeId;

const Color = Vector3;
const Vector3 = vector3_utilities.Vector3;

pub const World = struct { // Scene? (separate camera?)
    planes: Planes, // make array of things as 'thing_slice' instead of 'things'?
    triangles: Triangles,
    spheres: Spheres,

    camera: Camera, // instantiate inside main()? define Camera inside World? what about other structs?
    sky_color: Color,
    void_color: Color,

    pub const Json = struct { // declare camera stuff first? (check everywhere) put outside World? (in separate file?)
        planes: []struct {
            reference_point: Vector3,
            normal: Vector3,
            color: Color,
            shininess: f32,
        },
        triangles: []struct {
            vertices: [3]Vector3,
            color: Color,
            shininess: f32,
        },
        spheres: []struct {
            center: Vector3,
            radius: f32,
            color: Color,
            shininess: f32,
        },
        stl_objects: []struct { // const? (check everywhere)
            binary_file_sub_path: []const u8, // binary_file_sub_path?
            position: Vector3,
            yaw: f32,
            pitch: f32,
            scale: f32,
            color: Color,
            shininess: f32,
        },

        camera: struct { // look_from & look_at?
            position: Vector3,
            yaw: f32,
            pitch: f32,
            viewport_width: f32,
            fov: f32,
        },
        sky_color: Color,
        void_color: Color,

        pub fn initFromFile(allocator: std.mem.Allocator, sub_path: []const u8) !Json {
            const file = try std.fs.cwd().openFile(sub_path, .{});
            defer file.close();

            const string = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
            return std.json.parseFromSliceLeaky(Json, allocator, string, .{});
        }

        // TODO come up with a better solution than caching; stop worrying about gamma? (if yes, get rid of generic nature of Pixmap and rename to Ppm)
    };

    pub fn initFromJsonStruct(allocator: std.mem.Allocator, json: Json) !World { // put in Json? initializeWorldFromJsonStruct? createWorldFromJsonStruct?
        var world: World = undefined;

        world.planes = Planes{
            .geometries = try allocator.alloc(Planes.Geometry, json.planes.len),
            .materials = try allocator.alloc(Material, json.planes.len),
        };
        for (world.planes.geometries, world.planes.materials, json.planes) |*geometry, *material, json_plane| {
            geometry.reference_point = json_plane.reference_point;
            geometry.normal = vector3_utilities.unit(json_plane.normal); // geometry.unit_normal?

            material.color = json_plane.color;
            material.shininess = json_plane.shininess;
        }

        const getStlTriangleCountFromFile = struct { // ...
            inline fn getStlTriangleCountFromFile(file: std.fs.File) !u32 {
                var triangle_count: u32 = undefined;
                const byte_count = @sizeOf(@TypeOf(triangle_count));

                try file.seekTo(80);
                const bytes_read = try file.readAll(@as(*[byte_count]u8, @ptrCast(&triangle_count))); // comptime assert sizes? (if yes then make the size infered / use @sizeOf)
                if (bytes_read != byte_count)
                    return error.EndOfFile;

                return triangle_count;
            }
        }.getStlTriangleCountFromFile;

        const copyJsonStlObjectToTriangles = struct { // ...
            inline fn copyJsonObjectToTriangles(json_stl_object: anytype, file: std.fs.File, triangles: Triangles) !void {
                try file.seekBy(12 - 14);
                for (triangles.geometries, triangles.materials) |*geometry, *material| {
                    try file.seekBy(14);
                    var vertex_array: [3][3]f32 = undefined; // name? Vector3? directly write to geometry.vertex_array?

                    const bytes_read = try file.readAll(@as(*[36]u8, @ptrCast(&vertex_array)));
                    if (bytes_read != 36)
                        return error.EndOfFile;

                    inline for (0..3) |i| {
                        inline for (0..3) |j| { // bitcast from [3]f32 to Vector3?
                            geometry.vertex_array[i][j] = vertex_array[i][j];
                        }
                    }

                    const yaw = std.math.degreesToRadians(f32, json_stl_object.yaw);
                    const pitch = std.math.degreesToRadians(f32, json_stl_object.pitch);

                    const transformed_basis_vectors = vector3_utilities.transformBasisVectors(yaw, pitch);

                    for (&geometry.vertex_array) |*vertex| {
                        var transformed_vertex: Vector3 = @splat(0);
                        inline for (0..3) |i|
                            transformed_vertex += @as(Vector3, @splat(vertex.*[i])) * transformed_basis_vectors[i];

                        vertex.* = json_stl_object.position + @as(Vector3, @splat(json_stl_object.scale)) * transformed_vertex;
                    }
                    geometry.updateNormal(); // need a separate function?

                    material.color = json_stl_object.color;
                    material.shininess = json_stl_object.shininess;
                }
            }
        }.copyJsonObjectToTriangles;

        const json_stl_object_file_slice = try allocator.alloc(std.fs.File, json.stl_objects.len);
        const json_stl_object_triangle_count_slice = try allocator.alloc(usize, json.stl_objects.len);

        var total_triangle_count: usize = json.triangles.len;

        for (json.stl_objects, json_stl_object_file_slice, json_stl_object_triangle_count_slice) |json_stl_object, *file, *triangle_count| {
            file.* = try std.fs.cwd().openFile(json_stl_object.binary_file_sub_path, .{}); // do same thing everywhere? (passing fd instead of string)
            triangle_count.* = try getStlTriangleCountFromFile(file.*);
            total_triangle_count += triangle_count.*;
        }
        defer for (json_stl_object_file_slice) |file| { // divide this large block into a bunch of functions?
            file.close();
        };

        world.triangles = Triangles{
            .geometries = try allocator.alloc(Triangles.Geometry, total_triangle_count),
            .materials = try allocator.alloc(Material, total_triangle_count),
        };

        for (world.triangles.geometries[0..json.triangles.len], world.triangles.materials[0..json.triangles.len], json.triangles) |*geometry, *material, json_triangle| {
            geometry.vertex_array = json_triangle.vertices;
            geometry.updateNormal();

            material.color = json_triangle.color;
            material.shininess = json_triangle.shininess;
        }

        var start_index = json.triangles.len;
        for (json.stl_objects, json_stl_object_file_slice, json_stl_object_triangle_count_slice) |json_stl_object, file, triangle_count| {
            try copyJsonStlObjectToTriangles(json_stl_object, file, Triangles{
                .geometries = world.triangles.geometries[start_index..][0..triangle_count],
                .materials = world.triangles.materials[start_index..][0..triangle_count],
            });
            start_index += triangle_count;
        }

        world.spheres = Spheres{
            .geometries = try allocator.alloc(Spheres.Geometry, json.spheres.len),
            .materials = try allocator.alloc(Material, json.spheres.len),
        };
        for (world.spheres.geometries, world.spheres.materials, json.spheres) |*geometry, *material, json_sphere| {
            geometry.center = json_sphere.center;
            geometry.radius = json_sphere.radius;

            material.color = json_sphere.color;
            material.shininess = json_sphere.shininess;
        }

        const yaw = std.math.degreesToRadians(f32, json.camera.yaw);
        const pitch = std.math.degreesToRadians(f32, json.camera.pitch);
        const fov = std.math.degreesToRadians(f32, json.camera.fov);

        const transformed_basis_vectors = vector3_utilities.transformBasisVectors(yaw, pitch);

        world.camera = .{
            .viewport_center_coordinates = json.camera.position,
            .viewport_width = json.camera.viewport_width,
            .viewport_x_hat = transformed_basis_vectors[0],
            .viewport_y_hat = transformed_basis_vectors[1],
            .relative_focus_coordinates = @as(Vector3, @splat(json.camera.viewport_width / (2 * @tan(fov / 2)))) * transformed_basis_vectors[2],
        };

        world.sky_color = json.sky_color;
        world.void_color = json.void_color;

        return world;
    }

    pub fn raytrace(self: World, allocator: std.mem.Allocator, thread_count: usize, rays_per_pixel: u32, image: Pixmap(u8), max_ray_depth: u32, gamma: f32) !void { // check pass by value / reference and ownership everywhere
        const child_threads = try allocator.alloc(std.Thread, thread_count - 1);
        for (child_threads, 0..) |*thread, i| {
            thread.* = try std.Thread.spawn(.{}, raytraceThunk, .{ self, thread_count, i, rays_per_pixel, image, max_ray_depth, gamma });
        }
        self.raytraceThunk(thread_count, thread_count - 1, rays_per_pixel, image, max_ray_depth, gamma);
        for (child_threads) |thread| {
            thread.join(); // do using {} (against short hand notation)
        }
    }

    fn raytraceThunk(self: World, thread_count: usize, thread_index: usize, rays_per_pixel: u32, image: Pixmap(u8), max_ray_depth: u32, gamma: f32) void {
        var prng = std.rand.DefaultPrng.init(thread_index); // seed?
        const random = prng.random();

        var i: usize = thread_index;
        while (i < image.data.len / 3) : (i += thread_count) {
            if (thread_index == thread_count - 1) {
                std.debug.print("{}/{}\n", .{ i / thread_count, image.data.len / (3 * thread_count) });
            }
            var average_color: Vector3 = @splat(0);
            for (0..rays_per_pixel) |_| {
                var depth: u32 = 1;
                var color: Vector3 = @splat(1);
                var current_ray = self.camera.ray(image, random, i);
                while (true) {
                    const closest_object_data = Ray.getClosestObjectData(.{ self.planes, self.triangles, self.spheres }, current_ray);

                    if (closest_object_data.distance == std.math.floatMax(f32)) {
                        break;
                    }

                    const closest_object_material = switch (closest_object_data.parent_type_id) {
                        .planes => self.planes.materials[closest_object_data.index],
                        .spheres => self.spheres.materials[closest_object_data.index],
                        .triangles => self.triangles.materials[closest_object_data.index],
                    };

                    color *= closest_object_material.color;

                    if (depth == max_ray_depth) {
                        break;
                    }

                    depth += 1;

                    const hit_coordinates = current_ray.coordinates(closest_object_data.distance);
                    const normal = switch (closest_object_data.parent_type_id) {
                        .planes => self.planes.geometries[closest_object_data.index].getNormal(hit_coordinates),
                        .spheres => self.spheres.geometries[closest_object_data.index].getNormal(hit_coordinates),
                        .triangles => self.triangles.geometries[closest_object_data.index].getNormal(hit_coordinates),
                    };

                    if (-vector3_utilities.dot(current_ray.direction, normal) < Ray.hit_directness_epsilon) {
                        break;
                    }

                    current_ray.origin = hit_coordinates;
                    current_ray.direction = if (random.float(f32) < closest_object_material.shininess)
                        (current_ray.direction - @as(Vector3, @splat(2 * vector3_utilities.dot(current_ray.direction, normal))) * normal)
                    else
                        (vector3_utilities.unit(normal + vector3_utilities.randomUnit(random)));
                }
                average_color += (self.void_color + @as(Vector3, @splat((current_ray.direction[1] + 1) / 2)) * (self.sky_color - self.void_color)) * color; // ray_color instead of color, average_ray_color
            }
            average_color /= @as(Vector3, @splat(@as(f32, @floatFromInt(rays_per_pixel)))); // need @as()? propose removal of this @as business altogether or just allow me to coerce implicitly in cases like these
            inline for (0..3) |j| { // @ptrCast() for @Vector()? why don't @Vector()s support field access??
                image.data[3 * i + j] = @as(u8, @intFromFloat(std.math.pow(f32, average_color[j], 1 / gamma) * 255));
            }
        }
    }
};
