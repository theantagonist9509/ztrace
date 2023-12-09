const std = @import("std");

const Pixmap = @import("pixmap.zig").Pixmap;
const World = @import("world.zig").World;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var executable_sub_path: []const u8 = undefined;
    var json_sub_path: []const u8 = undefined;
    var num_threads: usize = undefined;
    var image_width: u32 = undefined;
    var image_height: u32 = undefined;
    var rays_per_pixel: u32 = undefined;
    var max_ray_depth: u32 = undefined;
    var gamma: f32 = undefined;
    var image_sub_path: []const u8 = undefined;

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    parseArgs(&args, .{ &executable_sub_path, &json_sub_path, &num_threads, &image_width, &image_height, &rays_per_pixel, &max_ray_depth, &gamma, &image_sub_path }) catch {
        try std.io.getStdErr().writer().print("Usage: {s} <json_sub_path> <num_threads> <image_width> <image_height> <rays_per_pixel> <max_ray_depth> <gamma> <image_sub_path>\n", .{executable_sub_path});
        std.process.exit(1);
    };

    const image = Pixmap(u8){
        .width = image_width,
        .height = image_height,
        .data = try arena.allocator().alloc(u8, 3 * image_width * image_height),
    };

    const world_json = try World.Json.initFromFile(allocator, json_sub_path);
    const world = try World.initFromJsonStruct(allocator, world_json);
    try world.raytrace(allocator, num_threads, rays_per_pixel, image, max_ray_depth, gamma);
    try image.writeToFile(image_sub_path);
}

inline fn parseArgs(args: *std.process.ArgIterator, field_pointers: anytype) !void {
    inline for (field_pointers) |field_pointer| {
        if (args.next()) |arg| {
            const T = @TypeOf(field_pointer.*);
            switch (@typeInfo(T)) {
                .Pointer => |info| {
                    if (info.size == .Slice and info.child == u8) {
                        field_pointer.* = @as([]const u8, @ptrCast(arg));
                    } else {
                        return error.ParseArgsError;
                    }
                },
                .Int => |info| {
                    if (info.signedness == .unsigned) {
                        field_pointer.* = try std.fmt.parseUnsigned(T, arg, 10);
                    } else {
                        return error.ParseArgsError;
                    }
                },
                .Float => {
                    field_pointer.* = try std.fmt.parseFloat(T, arg);
                },
                else => {
                    return error.ParseArgsError;
                },
            }
        } else {
            return error.ParseArgsError;
        }
    }

    if (args.skip()) {
        return error.ParseArgsError;
    }
}
