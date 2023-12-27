const std = @import("std");

const Ppm = @import("ppm.zig").Ppm;
const ThreadSafeProgressBar = @import("threadsafeprogressbar.zig").ThreadSafeProgressBar;
const World = @import("world.zig").World;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var parsed_args: struct {
        executable_sub_path: []const u8,
        json_sub_path: []const u8,
        num_threads: usize,
        image_width: u32,
        image_height: u32,
        rays_per_pixel: u32,
        max_ray_depth: u32,
        gamma: f32,
        image_sub_path: []const u8,
    } = undefined;

    parseArgs(&args, &parsed_args) catch {
        try printUsageErrorMessage(parsed_args);
        return error.UsageError;
    };

    const image = Ppm{
        .width = parsed_args.image_width,
        .height = parsed_args.image_height,
        .data = try arena.allocator().alloc(u8, 3 * parsed_args.image_width * parsed_args.image_height),
    };

    const world_json = try World.Json.initFromFile(allocator, parsed_args.json_sub_path);
    const world = try World.initFromJsonStruct(allocator, world_json);

    var progress_bar: ThreadSafeProgressBar = undefined;
    try world.raytrace(allocator, parsed_args.num_threads, parsed_args.rays_per_pixel, image, parsed_args.max_ray_depth, parsed_args.gamma, &progress_bar);

    try image.writeToFile(parsed_args.image_sub_path);
}

inline fn parseArgs(args: *std.process.ArgIterator, parsed_args_out_pointer: anytype) !void {
    inline for (std.meta.fields(@TypeOf(parsed_args_out_pointer.*))) |field_info| {
        if (args.next()) |arg| {
            const T = field_info.type;
            const name = field_info.name;

            switch (@typeInfo(T)) {
                .Pointer => |info| {
                    if (info.size == .Slice and info.child == u8) {
                        @field(parsed_args_out_pointer.*, name) = @as([]const u8, @ptrCast(arg));
                    } else {
                        @compileError("Parsing of type " ++ @typeName(T) ++ " not handled");
                    }
                },
                .Int => |info| {
                    if (info.signedness == .unsigned) {
                        @field(parsed_args_out_pointer.*, name) = try std.fmt.parseUnsigned(T, arg, 10);
                    } else {
                        @compileError("Parsing of type " ++ @typeName(T) ++ " not handled");
                    }
                },
                .Float => {
                    @field(parsed_args_out_pointer.*, name) = try std.fmt.parseFloat(T, arg);
                },
                else => @compileError("Parsing of type " ++ @typeName(T) ++ " not handled"),
            }
        } else {
            return error.ParseArgsError;
        }
    }

    if (args.skip())
        return error.ParseArgsError;
}

fn printUsageErrorMessage(args_struct: anytype) !void {
    try std.io.getStdOut().writer().print("Usage: {s}", .{args_struct.executable_sub_path});

    for (std.meta.fieldNames(@TypeOf(args_struct)).*[1..]) |field_name|
        try std.io.getStdOut().writer().print(" <{s}>", .{field_name});

    try std.io.getStdOut().writeAll("\n");
}
