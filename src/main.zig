const std = @import("std");

const World = @import("world.zig").World;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var args = try std.process.argsWithAllocator(arena.allocator());
    _ = args.skip();

    var json_sub_path: []const u8 = undefined;
    var num_threads: usize = undefined;
    var max_depth: u32 = undefined;
    var image_sub_path: []const u8 = undefined;

    inline for (.{ &json_sub_path, &num_threads, &max_depth, &image_sub_path, }) |field| {
        if (@TypeOf(field.*) == []const u8) {
            if (args.next()) |next| {
                field.* = next[0..next.len];
            } else {
                printUsageError();
            }
        } else if (@typeInfo(@TypeOf(field.*)).Int.signedness == .unsigned) {
            if (args.next()) |next| {
                field.* = std.fmt.parseUnsigned(@TypeOf(field.*), next, 10) catch printUsageError();
            } else {
                printUsageError();
            }
        }
    }

    var world = try World.initFromJson(arena.allocator(), json_sub_path);
    try world.raytrace(arena.allocator(), num_threads, max_depth);
    try world.camera.image.writeToFile(image_sub_path);
}

fn printUsageError() noreturn {
    std.io.getStdErr().writeAll("usage: ztrace [json_sub_path] [num_threads] [max_depth] [image_sub_path]\n") catch @panic("Unable to write to stderr\n");
    std.process.exit(1);
}
