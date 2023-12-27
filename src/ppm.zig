const std = @import("std");

pub const Ppm = struct {
    width: usize,
    height: usize,
    data: []u8, // not [][3]u8 as ptrCast from [][3]u8 to []u8 has not yet been implemented

    pub fn writeToFile(self: Ppm, sub_path: []const u8) !void {
        const file = try std.fs.cwd().createFile(sub_path, .{}); // accept open file instead?
        defer file.close();

        try file.writer().print("P6\n{} {}\n255\n", .{ self.width, self.height });
        try file.writeAll(self.data);
    }
};
