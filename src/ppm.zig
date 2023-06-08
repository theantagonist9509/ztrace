const std = @import("std");

pub const Ppm = struct {
    width: usize,
    height: usize,
    data: []u8 = &[_]u8{},

    pub fn writeToFile(self: Ppm, sub_path: []const u8) !void {
        const file = try std.fs.cwd().createFile(sub_path, .{});

        try file.writer().print("P6\n{} {}\n255\n", .{
            self.width,
            self.height,
        });
        try file.seekFromEnd(0);
        try file.writeAll(self.data);
    }
};
