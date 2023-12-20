const std = @import("std");

pub const ThreadSafeProgressBar = struct {
    mutex: std.Thread.Mutex,

    tick_count: usize,
    ticks_for_completion: usize,

    const bar_width = 50;

    pub fn start(self: *ThreadSafeProgressBar, ticks_for_completion: usize) void {
        self.mutex = .{};
        self.tick_count = 0;
        self.ticks_for_completion = ticks_for_completion;

        self.print();
    }

    pub fn finish() void {
        std.io.getStdOut().writeAll("\n") catch unreachable;
    }

    pub fn advance(self: *ThreadSafeProgressBar) void {
        self.mutex.lock();
        defer self.mutex.unlock();

        self.tick_count += 1;

        if ((100 * self.tick_count) % self.ticks_for_completion == 0)
            self.print();
    }

    fn print(self: *ThreadSafeProgressBar) void {
        var bar = [_]u8{ '\r', '[' } ++ [_]u8{' '} ** bar_width ++ [_]u8{']'};
        @memset(bar[2..][0 .. (bar_width * self.tick_count) / self.ticks_for_completion], '#');

        std.io.getStdOut().writeAll(&bar) catch unreachable;
        std.io.getStdOut().writer().print(" {}%", .{(100 * self.tick_count) / self.ticks_for_completion}) catch unreachable; // wrap both statements in a block and unify catch block
    }
};
