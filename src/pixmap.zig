const std = @import("std");

pub fn Pixmap(comptime T: type) type {
    return struct {
        width: usize,
        height: usize,
        data: []T,

        pub fn writeToFile(self: Pixmap(T), sub_path: []const u8) !void {
            const file = try std.fs.cwd().createFile(sub_path, .{}); // accept open file instead?
            defer file.close();

            try file.writer().print("P6\n{} {}\n255\n", .{ self.width, self.height });
            try file.seekFromEnd(0);
            try file.writeAll(self.data);
        }
    };
}
