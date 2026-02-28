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

    try app.get("/robots.txt", robotsTxt, .{
        .summary = "Robots.txt for search engine crawlers",
    });

    try app.get("/sitemap.xml", sitemapXml, .{
        .summary = "XML sitemap for search engines",
    });
}

fn healthCheck(_: *zigmund.Request, alloc: std.mem.Allocator) !zigmund.Response {
    return zigmund.Response.json(alloc, .{
        .status = "ok",
        .framework = "zigmund",
        .version = "0.1.0",
    });
}

fn robotsTxt(_: *zigmund.Request, _: std.mem.Allocator) !zigmund.Response {
    return zigmund.Response.text(
        \\User-agent: *
        \\Allow: /
        \\Disallow: /api/
        \\Disallow: /health
        \\
        \\# AI Search Crawlers
        \\User-agent: GPTBot
        \\Allow: /
        \\
        \\User-agent: Google-Extended
        \\Allow: /
        \\
        \\User-agent: ChatGPT-User
        \\Allow: /
        \\
        \\User-agent: PerplexityBot
        \\Allow: /
        \\
        \\User-agent: ClaudeBot
        \\Allow: /
        \\
        \\User-agent: Applebot
        \\Allow: /
        \\
        \\User-agent: anthropic-ai
        \\Allow: /
        \\
        \\Sitemap: https://zigmund.io/sitemap.xml
        \\
    );
}

fn sitemapXml(_: *zigmund.Request, _: std.mem.Allocator) !zigmund.Response {
    return .{
        .status = .ok,
        .body =
            \\<?xml version="1.0" encoding="UTF-8"?>
            \\<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
            \\  <url>
            \\    <loc>https://zigmund.io/</loc>
            \\    <lastmod>2026-02-28</lastmod>
            \\    <changefreq>weekly</changefreq>
            \\    <priority>1.0</priority>
            \\  </url>
            \\</urlset>
            \\
        ,
        .content_type = "application/xml; charset=utf-8",
    };
}
