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

    const executable_sub_path = args.next().?;

    const ParsedArgs = struct {
        json_sub_path: []const u8,
        num_threads: usize,
        image_width: u32,
        image_height: u32,
        rays_per_pixel: u32,
        max_ray_depth: u32,
        gamma: f32,
        image_sub_path: []const u8,
    };

    const parsed_args = parseArgs(ParsedArgs, &args) catch {
        try printUsageErrorMessage(ParsedArgs, executable_sub_path);
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

inline fn parseArgs(comptime ParsedArgs: type, args: *std.process.ArgIterator) !ParsedArgs {
    var parsed_args: ParsedArgs = undefined;

    inline for (std.meta.fields(ParsedArgs)) |field_info| {
        if (args.next()) |arg| {
            switch (@typeInfo(field_info.type)) {
                .Pointer => |pointer_info| {
                    if (pointer_info.size == .Slice and pointer_info.child == u8) {
                        @field(parsed_args, field_info.name) = arg;
                    } else {
                        @compileError("Parsing of type " ++ @typeName(field_info.type) ++ " not handled");
                    }
                },
                .Int => |int_info| {
                    if (int_info.signedness == .unsigned) {
                        @field(parsed_args, field_info.name) = try std.fmt.parseUnsigned(field_info.type, arg, 10);
                    } else {
                        @compileError("Parsing of type " ++ @typeName(field_info.type) ++ " not handled");
                    }
                },
                .Float => {
                    @field(parsed_args, field_info.name) = try std.fmt.parseFloat(field_info.type, arg);
                },
                else => @compileError("Parsing of type " ++ @typeName(field_info.type) ++ " not handled"),
            }
        } else {
            return error.ParseArgsError;
        }
    }

    if (args.skip())
        return error.ParseArgsError;

    return parsed_args;
}

fn printUsageErrorMessage(comptime ParsedArgs: type, executable_sub_path: []const u8) !void {
    try std.io.getStdOut().writer().print("Usage: {s}", .{executable_sub_path});

    for (std.meta.fieldNames(ParsedArgs).*) |field_name|
        try std.io.getStdOut().writer().print(" <{s}>", .{field_name});

    try std.io.getStdOut().writeAll("\n");
}
