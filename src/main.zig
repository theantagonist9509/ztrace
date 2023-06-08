const std = @import("std");

const Ppm = @import("ppm.zig").Ppm;
const Sphere = @import("sphere.zig").Sphere;
const World = @import("world.zig").World;

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var world = try World.initFromJson(arena.allocator(), "example.json");

    try world.raytrace(arena.allocator(), 1, 100); // TODO cmd line arg parsing
    try world.camera.image.writeToFile("image.ppm");
}
