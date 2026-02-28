const std = @import("std");
const zigmund = @import("zigmund");

const pages = @import("pages.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var app = try zigmund.App.init(allocator, .{
        .title = "Zigmund",
        .version = "0.1.0",
    });
    defer app.deinit();

    try buildRoutes(&app);

    try zigmund.mountStaticFiles(&app, "/static", "public", .{
        .cache_control = "public, max-age=3600",
    });

    try app.serve(.{
        .host = "0.0.0.0",
        .port = 3000,
    });
}

fn buildRoutes(app: *zigmund.App) !void {
    try app.get("/", pages.home, .{
        .summary = "Homepage",
    });

    try app.get("/health", healthCheck, .{
        .summary = "Health check",
    });
}

fn healthCheck(_: *zigmund.Request, alloc: std.mem.Allocator) !zigmund.Response {
    return zigmund.Response.json(alloc, .{
        .status = "ok",
        .framework = "zigmund",
        .version = "0.1.0",
    });
}
