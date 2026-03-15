const std = @import("std");
const zigmund = @import("zigmund");

const Value = zigmund.template.Value;

// ── Cached state loaded at startup ──

var manifest_json: []const u8 = "";
var search_index_json: []const u8 = "";
var learn_path_json: []const u8 = "";
var cached_pages: std.StringHashMap([]const u8) = undefined;
var initialized: bool = false;
var init_alloc: std.mem.Allocator = undefined;

// ── Parsed manifest structures ──

const PageInfo = struct {
    title: []const u8,
    section: ?[]const u8,
    path: []const u8,
    prev_path: ?[]const u8,
    prev_title: ?[]const u8,
    next_path: ?[]const u8,
    next_title: ?[]const u8,
};

const SectionInfo = struct {
    title: []const u8,
    icon: []const u8,
    description: []const u8,
    pages: []const []const u8,
    count: usize,
};

var page_map: std.StringHashMap(PageInfo) = undefined;
var section_map: std.StringHashMap(SectionInfo) = undefined;
var section_order: [6][]const u8 = undefined;
var section_count: usize = 0;

// ── Learn path structures ──

const LearnSection = struct {
    title: []const u8,
    description: []const u8,
    pages: []const []const u8,
};

var learn_sections: [10]LearnSection = undefined;
var learn_section_count: usize = 0;

// Flat list of all learn pages for prev/next navigation
var learn_flat_pages: [100][]const u8 = undefined;
var learn_flat_count: usize = 0;
// Map from page path to learn step index (1-based)
var learn_step_map: std.StringHashMap(usize) = undefined;
// Map from page path to learn section title
var learn_section_title_map: std.StringHashMap([]const u8) = undefined;

pub fn init(allocator: std.mem.Allocator) !void {
    if (initialized) return;
    init_alloc = allocator;

    // Load manifest
    manifest_json = std.fs.cwd().readFileAlloc(allocator, "content/docs/_manifest.json", 4 * 1024 * 1024) catch "";

    // Load search index
    search_index_json = std.fs.cwd().readFileAlloc(allocator, "content/docs/_search_index.json", 4 * 1024 * 1024) catch "";

    // Load learn path
    learn_path_json = std.fs.cwd().readFileAlloc(allocator, "content/learn_path.json", 256 * 1024) catch "";

    // Initialize caches
    cached_pages = std.StringHashMap([]const u8).init(allocator);
    page_map = std.StringHashMap(PageInfo).init(allocator);
    section_map = std.StringHashMap(SectionInfo).init(allocator);
    learn_step_map = std.StringHashMap(usize).init(allocator);
    learn_section_title_map = std.StringHashMap([]const u8).init(allocator);

    // Parse manifest
    if (manifest_json.len > 0) {
        parseManifest(allocator) catch |err| {
            std.log.err("Failed to parse manifest: {}", .{err});
        };
    }

    // Parse learn path
    if (learn_path_json.len > 0) {
        parseLearnPath(allocator) catch |err| {
            std.log.err("Failed to parse learn path: {}", .{err});
        };
    }

    // Preload all HTML fragments
    preloadPages(allocator) catch |err| {
        std.log.err("Failed to preload pages: {}", .{err});
    };

    // Copy search index to static directory for client-side access
    copySearchIndex(allocator) catch |err| {
        std.log.err("Failed to copy search index: {}", .{err});
    };

    initialized = true;
    std.log.info("Documentation loaded: {} pages cached", .{cached_pages.count()});
}

fn copySearchIndex(allocator: std.mem.Allocator) !void {
    if (search_index_json.len == 0) return;
    // Ensure the docs static directory exists
    std.fs.cwd().makePath("public/docs") catch {};
    const dest_path = try std.fs.path.join(allocator, &.{ "public", "docs", "_search_index.json" });
    defer allocator.free(dest_path);
    const file = try std.fs.cwd().createFile(dest_path, .{});
    defer file.close();
    try file.writeAll(search_index_json);
}

fn parseManifest(allocator: std.mem.Allocator) !void {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, manifest_json, .{});
    // Don't defer deinit — we keep references to the parsed data

    const root = parsed.value;
    const sections_obj = root.object.get("sections") orelse return;
    const pages_obj = root.object.get("pages") orelse return;

    // Parse sections in order
    const section_keys = [_][]const u8{ "tutorial", "reference", "advanced", "how-to", "zig-guide", "deployment" };
    for (section_keys) |key| {
        const sec_val = sections_obj.object.get(key) orelse continue;
        const sec_obj = sec_val.object;

        const pages_arr = sec_obj.get("pages") orelse continue;
        const page_paths = try allocator.alloc([]const u8, pages_arr.array.items.len);
        for (pages_arr.array.items, 0..) |item, i| {
            page_paths[i] = item.string;
        }

        const sec_info = SectionInfo{
            .title = (sec_obj.get("title") orelse continue).string,
            .icon = (sec_obj.get("icon") orelse continue).string,
            .description = (sec_obj.get("description") orelse continue).string,
            .pages = page_paths,
            .count = page_paths.len,
        };
        try section_map.put(key, sec_info);
        section_order[section_count] = key;
        section_count += 1;
    }

    // Parse pages
    var pages_iter = pages_obj.object.iterator();
    while (pages_iter.next()) |entry| {
        const page_obj = entry.value_ptr.object;
        const page_info = PageInfo{
            .title = (page_obj.get("title") orelse continue).string,
            .section = if (page_obj.get("section")) |s| (if (s == .null) null else s.string) else null,
            .path = (page_obj.get("path") orelse continue).string,
            .prev_path = if (page_obj.get("prev")) |prev| prev.object.get("path").?.string else null,
            .prev_title = if (page_obj.get("prev")) |prev| prev.object.get("title").?.string else null,
            .next_path = if (page_obj.get("next")) |next| next.object.get("path").?.string else null,
            .next_title = if (page_obj.get("next")) |next| next.object.get("title").?.string else null,
        };
        try page_map.put(entry.key_ptr.*, page_info);
    }
}

fn parseLearnPath(allocator: std.mem.Allocator) !void {
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, learn_path_json, .{});

    const root = parsed.value;
    const sections_arr = root.object.get("sections") orelse return;

    var global_step: usize = 0;
    for (sections_arr.array.items) |sec_val| {
        const sec_obj = sec_val.object;
        const pages_arr = sec_obj.get("pages") orelse continue;
        const page_paths = try allocator.alloc([]const u8, pages_arr.array.items.len);
        const sec_title = (sec_obj.get("title") orelse continue).string;

        for (pages_arr.array.items, 0..) |item, i| {
            page_paths[i] = item.string;
            learn_flat_pages[learn_flat_count] = item.string;
            learn_flat_count += 1;
            global_step += 1;
            try learn_step_map.put(item.string, global_step);
            try learn_section_title_map.put(item.string, sec_title);
        }

        learn_sections[learn_section_count] = LearnSection{
            .title = sec_title,
            .description = (sec_obj.get("description") orelse continue).string,
            .pages = page_paths,
        };
        learn_section_count += 1;
    }
}

fn preloadPages(allocator: std.mem.Allocator) !void {
    var iter = page_map.iterator();
    while (iter.next()) |entry| {
        const doc_path = entry.key_ptr.*;
        const file_path = try std.fmt.allocPrint(allocator, "content/docs/{s}.html", .{doc_path});
        defer allocator.free(file_path);

        const content = std.fs.cwd().readFileAlloc(allocator, file_path, 2 * 1024 * 1024) catch continue;
        try cached_pages.put(doc_path, content);
    }
}

// ── Build sidebar HTML ──

fn buildSidebarHtml(allocator: std.mem.Allocator, current_path: []const u8, base_url: []const u8) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    const w = buf.writer(allocator);

    var i: usize = 0;
    while (i < section_count) : (i += 1) {
        const sec_key = section_order[i];
        const sec = section_map.get(sec_key) orelse continue;

        // Check if current page is in this section
        var section_active = false;
        for (sec.pages) |p| {
            if (std.mem.eql(u8, p, current_path)) {
                section_active = true;
                break;
            }
        }

        try w.print("<div class=\"docs-sidebar-section\">", .{});
        try w.print("<div class=\"docs-sidebar-heading{s}\">", .{if (!section_active) " collapsed" else ""});
        try w.print("<span>{s}</span>", .{sec.title});
        try w.print("<span class=\"toggle-icon\">▼</span>", .{});
        try w.print("</div>", .{});
        try w.print("<ul class=\"docs-sidebar-links{s}\">", .{if (!section_active) " collapsed" else ""});

        for (sec.pages) |page_path| {
            const page = page_map.get(page_path) orelse continue;
            const is_active = std.mem.eql(u8, page_path, current_path);
            try w.print("<li><a href=\"{s}{s}\"{s}>{s}</a></li>", .{
                base_url,
                page_path,
                if (is_active) " class=\"active\"" else "",
                page.title,
            });
        }

        try w.print("</ul></div>", .{});
    }

    return buf.toOwnedSlice(allocator);
}

// ── Handlers ──

pub fn docsLanding(_: *zigmund.Request, allocator: std.mem.Allocator) !zigmund.Response {
    if (!initialized) try init(allocator);

    var templates = try zigmund.TemplatesIntegration.init(allocator, "templates");
    defer templates.deinit();

    // Build sections data for template
    var sections_list: [6]Value = undefined;
    var sc: usize = 0;
    var i: usize = 0;
    while (i < section_count) : (i += 1) {
        const sec_key = section_order[i];
        const sec = section_map.get(sec_key) orelse continue;

        const first_page = if (sec.pages.len > 0) sec.pages[0] else sec_key;

        const keys = [_][]const u8{ "title", "icon", "description", "count", "first_page" };
        const vals = [_]Value{
            .{ .string = sec.title },
            .{ .string = sec.icon },
            .{ .string = sec.description },
            .{ .string = try std.fmt.allocPrint(allocator, "{d}", .{sec.count}) },
            .{ .string = first_page },
        };

        const owned_keys = try allocator.dupe([]const u8, &keys);
        const owned_vals = try allocator.dupe(Value, &vals);

        sections_list[sc] = .{ .map = .{ .keys = owned_keys, .values = owned_vals } };
        sc += 1;
    }

    const total_str = try std.fmt.allocPrint(allocator, "{d}", .{page_map.count()});

    return templates.renderJinjaHtmlResponse("docs_landing.html", &.{
        .{ "page_title", Value{ .string = "Documentation - Zigmund Framework" } },
        .{ "page_description", Value{ .string = "Comprehensive documentation for the Zigmund web framework. Tutorials, API reference, how-to guides, and deployment instructions." } },
        .{ "page_canonical", Value{ .string = "/docs" } },
        .{ "og_type", Value{ .string = "website" } },
        .{ "sections", Value{ .list = sections_list[0..sc] } },
        .{ "total_pages", Value{ .string = total_str } },
    });
}

pub fn docsHandler(req: *zigmund.Request, allocator: std.mem.Allocator) !zigmund.Response {
    if (!initialized) try init(allocator);

    const doc_path = req.param("doc_path") orelse return notFound(allocator);

    // Check if this is a section index request (e.g., /docs/tutorial)
    // Redirect to the first page of that section
    if (section_map.get(doc_path)) |sec| {
        if (sec.pages.len > 0) {
            const redirect_url = try std.fmt.allocPrint(allocator, "/docs/{s}", .{sec.pages[0]});
            return zigmund.Response.redirect(allocator, redirect_url, .found);
        }
    }

    return renderDocPage(allocator, doc_path, "/docs/", "docs_layout.html");
}

pub fn learnLanding(_: *zigmund.Request, allocator: std.mem.Allocator) !zigmund.Response {
    if (!initialized) try init(allocator);

    var templates = try zigmund.TemplatesIntegration.init(allocator, "templates");
    defer templates.deinit();

    // Build learn sections data
    var sections_list: [10]Value = undefined;
    var global_step: usize = 0;

    var i: usize = 0;
    while (i < learn_section_count) : (i += 1) {
        const sec = learn_sections[i];

        // Build page list for this section
        var page_values: [30]Value = undefined;
        for (sec.pages, 0..) |page_path, j| {
            global_step += 1;
            const page = page_map.get(page_path);
            const title = if (page) |p| p.title else page_path;

            const step_str = try std.fmt.allocPrint(allocator, "{d:0>2}", .{global_step});

            const p_keys = [_][]const u8{ "path", "title", "step" };
            const p_vals = [_]Value{
                .{ .string = page_path },
                .{ .string = title },
                .{ .string = step_str },
            };

            const owned_keys = try allocator.dupe([]const u8, &p_keys);
            const owned_vals = try allocator.dupe(Value, &p_vals);
            page_values[j] = .{ .map = .{ .keys = owned_keys, .values = owned_vals } };
        }

        const owned_pages = try allocator.dupe(Value, page_values[0..sec.pages.len]);

        const s_keys = [_][]const u8{ "title", "description", "pages" };
        const s_vals = [_]Value{
            .{ .string = sec.title },
            .{ .string = sec.description },
            .{ .list = owned_pages },
        };

        const owned_keys = try allocator.dupe([]const u8, &s_keys);
        const owned_vals = try allocator.dupe(Value, &s_vals);
        sections_list[i] = .{ .map = .{ .keys = owned_keys, .values = owned_vals } };
    }

    return templates.renderJinjaHtmlResponse("learn_landing.html", &.{
        .{ "page_title", Value{ .string = "Learn Zigmund - Guided Learning Path" } },
        .{ "page_description", Value{ .string = "A guided learning path for the Zigmund web framework. Go from beginner to advanced with structured tutorials and examples." } },
        .{ "page_canonical", Value{ .string = "/learn" } },
        .{ "og_type", Value{ .string = "website" } },
        .{ "learn_sections", Value{ .list = sections_list[0..learn_section_count] } },
    });
}

pub fn learnHandler(req: *zigmund.Request, allocator: std.mem.Allocator) !zigmund.Response {
    if (!initialized) try init(allocator);

    const doc_path = req.param("doc_path") orelse return notFound(allocator);

    return renderLearnPage(allocator, doc_path);
}

fn renderDocPage(allocator: std.mem.Allocator, doc_path: []const u8, base_url: []const u8, template_name: []const u8) !zigmund.Response {
    const page = page_map.get(doc_path) orelse return notFound(allocator);
    const content = cached_pages.get(doc_path) orelse return notFound(allocator);

    var templates = try zigmund.TemplatesIntegration.init(allocator, "templates");
    defer templates.deinit();

    const sidebar_html = try buildSidebarHtml(allocator, doc_path, base_url);

    // Section info
    const section_title = if (page.section) |sec_key| (if (section_map.get(sec_key)) |sec| sec.title else null) else null;
    const section_slug = page.section;

    // Prev/next URLs
    const has_prev = page.prev_path != null;
    const has_next = page.next_path != null;
    const prev_url = if (page.prev_path) |p| try std.fmt.allocPrint(allocator, "{s}{s}", .{ base_url, p }) else "";
    const next_url = if (page.next_path) |p| try std.fmt.allocPrint(allocator, "{s}{s}", .{ base_url, p }) else "";

    const meta_desc = try std.fmt.allocPrint(allocator, "{s} - Zigmund Framework Documentation", .{page.title});
    const page_title = try std.fmt.allocPrint(allocator, "{s} - Zigmund Docs", .{page.title});
    const canonical = try std.fmt.allocPrint(allocator, "/docs/{s}", .{doc_path});

    return templates.renderJinjaHtmlResponse(template_name, &.{
        .{ "page_title", Value{ .string = page_title } },
        .{ "page_description", Value{ .string = meta_desc } },
        .{ "page_canonical", Value{ .string = canonical } },
        .{ "og_type", Value{ .string = "article" } },
        .{ "title", Value{ .string = page.title } },
        .{ "content", Value{ .string = content } },
        .{ "sidebar_html", Value{ .string = sidebar_html } },
        .{ "current_path", Value{ .string = doc_path } },
        .{ "section_title", Value{ .string = section_title orelse "" } },
        .{ "section_slug", Value{ .string = section_slug orelse "" } },
        .{ "has_prev", Value{ .boolean = has_prev } },
        .{ "has_next", Value{ .boolean = has_next } },
        .{ "prev_url", Value{ .string = prev_url } },
        .{ "prev_title", Value{ .string = page.prev_title orelse "" } },
        .{ "next_url", Value{ .string = next_url } },
        .{ "next_title", Value{ .string = page.next_title orelse "" } },
        .{ "meta_description", Value{ .string = meta_desc } },
    });
}

fn renderLearnPage(allocator: std.mem.Allocator, doc_path: []const u8) !zigmund.Response {
    const page = page_map.get(doc_path) orelse return notFound(allocator);
    const content = cached_pages.get(doc_path) orelse return notFound(allocator);

    var templates = try zigmund.TemplatesIntegration.init(allocator, "templates");
    defer templates.deinit();

    const sidebar_html = try buildSidebarHtml(allocator, doc_path, "/learn/");

    // Learn path progress
    const step_idx = learn_step_map.get(doc_path) orelse 1;
    const learn_sec_title = learn_section_title_map.get(doc_path) orelse "Learn";

    const step_str = try std.fmt.allocPrint(allocator, "{d}", .{step_idx});
    const total_str = try std.fmt.allocPrint(allocator, "{d}", .{learn_flat_count});
    const percent = (step_idx * 100) / if (learn_flat_count > 0) learn_flat_count else 1;
    const percent_str = try std.fmt.allocPrint(allocator, "{d}", .{percent});

    // Prev/next in learn path order
    var prev_url: []const u8 = "";
    var prev_title: []const u8 = "";
    var next_url: []const u8 = "";
    var next_title: []const u8 = "";
    var has_prev = false;
    var has_next = false;

    // Find position in learn flat list
    var flat_idx: ?usize = null;
    for (learn_flat_pages[0..learn_flat_count], 0..) |p, idx| {
        if (std.mem.eql(u8, p, doc_path)) {
            flat_idx = idx;
            break;
        }
    }

    if (flat_idx) |fi| {
        if (fi > 0) {
            has_prev = true;
            const pp = learn_flat_pages[fi - 1];
            prev_url = try std.fmt.allocPrint(allocator, "/learn/{s}", .{pp});
            prev_title = if (page_map.get(pp)) |p| p.title else pp;
        }
        if (fi + 1 < learn_flat_count) {
            has_next = true;
            const np = learn_flat_pages[fi + 1];
            next_url = try std.fmt.allocPrint(allocator, "/learn/{s}", .{np});
            next_title = if (page_map.get(np)) |p| p.title else np;
        }
    }

    const meta_desc = try std.fmt.allocPrint(allocator, "{s} - Learn Zigmund", .{page.title});
    const page_title_str = try std.fmt.allocPrint(allocator, "{s} - Learn Zigmund", .{page.title});
    const canonical = try std.fmt.allocPrint(allocator, "/learn/{s}", .{doc_path});

    return templates.renderJinjaHtmlResponse("learn_layout.html", &.{
        .{ "page_title", Value{ .string = page_title_str } },
        .{ "page_description", Value{ .string = meta_desc } },
        .{ "page_canonical", Value{ .string = canonical } },
        .{ "og_type", Value{ .string = "article" } },
        .{ "title", Value{ .string = page.title } },
        .{ "content", Value{ .string = content } },
        .{ "sidebar_html", Value{ .string = sidebar_html } },
        .{ "current_path", Value{ .string = doc_path } },
        .{ "learn_section_title", Value{ .string = learn_sec_title } },
        .{ "learn_step", Value{ .string = step_str } },
        .{ "learn_total", Value{ .string = total_str } },
        .{ "learn_percent", Value{ .string = percent_str } },
        .{ "has_prev", Value{ .boolean = has_prev } },
        .{ "has_next", Value{ .boolean = has_next } },
        .{ "prev_url", Value{ .string = prev_url } },
        .{ "prev_title", Value{ .string = prev_title } },
        .{ "next_url", Value{ .string = next_url } },
        .{ "next_title", Value{ .string = next_title } },
        .{ "meta_description", Value{ .string = meta_desc } },
    });
}

fn notFound(allocator: std.mem.Allocator) !zigmund.Response {
    _ = allocator;
    return .{
        .status = .not_found,
        .body =
            \\<!DOCTYPE html>
            \\<html lang="en">
            \\<head>
            \\  <meta charset="UTF-8">
            \\  <meta name="viewport" content="width=device-width, initial-scale=1.0">
            \\  <title>404 - Page Not Found</title>
            \\  <link rel="preconnect" href="https://fonts.googleapis.com">
            \\  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
            \\  <link href="https://fonts.googleapis.com/css2?family=VT323&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
            \\  <link rel="stylesheet" href="/static/css/style.css">
            \\  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><text y='14' font-size='14'>⚡</text></svg>">
            \\</head>
            \\<body>
            \\  <div class="scanlines"></div>
            \\  <nav class="nav">
            \\    <div class="nav-inner">
            \\      <a href="/" class="nav-logo">
            \\        <span class="logo-icon">⚡</span>
            \\        <span class="logo-text">zigmund</span>
            \\        <span class="logo-ver">v0.1.0</span>
            \\      </a>
            \\      <div class="nav-links">
            \\        <a href="/learn">Learn</a>
            \\        <a href="/docs">Docs</a>
            \\        <a href="https://github.com/Softorize/zigmund" target="_blank" rel="noopener">GitHub <span class="ext-icon">↗</span></a>
            \\      </div>
            \\    </div>
            \\  </nav>
            \\  <section class="hero">
            \\    <div class="container" style="text-align:center">
            \\      <div class="terminal-window" style="max-width:500px;margin:0 auto 32px">
            \\        <div class="terminal-bar">
            \\          <div class="terminal-buttons"><span class="tbtn tbtn-close"></span><span class="tbtn tbtn-min"></span><span class="tbtn tbtn-max"></span></div>
            \\          <div class="terminal-title">404</div>
            \\          <div class="terminal-bar-right"></div>
            \\        </div>
            \\        <div class="terminal-body">
            \\          <p class="terminal-tagline"><span class="prompt-user">zigmund</span><span class="prompt-at">@</span><span class="prompt-host">docs</span><span class="prompt-colon">:</span><span class="prompt-path">~</span><span class="prompt-dollar">$</span> <span style="color:var(--red)">error: page not found</span></p>
            \\        </div>
            \\      </div>
            \\      <h1 class="hero-title">Page Not Found</h1>
            \\      <p style="color:var(--text-dim);margin-bottom:24px">The documentation page you're looking for doesn't exist.</p>
            \\      <div class="hero-actions">
            \\        <a href="/docs" class="btn btn-primary"><span class="btn-icon">◆</span> Browse Docs</a>
            \\        <a href="/learn" class="btn btn-secondary"><span class="btn-icon">▶</span> Start Learning</a>
            \\      </div>
            \\    </div>
            \\  </section>
            \\</body>
            \\</html>
        ,
        .content_type = "text/html; charset=utf-8",
    };
}

// ── Sitemap generation ──

pub fn sitemapEntries(allocator: std.mem.Allocator) ![]const u8 {
    if (!initialized) try init(allocator);

    var buf: std.ArrayList(u8) = .empty;
    const w = buf.writer(allocator);

    var iter = page_map.iterator();
    while (iter.next()) |entry| {
        const path = entry.key_ptr.*;
        const page = entry.value_ptr.*;

        // Determine priority based on section
        const priority: []const u8 = if (page.section == null)
            "0.7"
        else if (std.mem.eql(u8, page.section.?, "tutorial"))
            "0.8"
        else if (std.mem.eql(u8, page.section.?, "reference"))
            "0.7"
        else
            "0.6";

        try w.print(
            \\  <url>
            \\    <loc>https://zigmund.io/docs/{s}</loc>
            \\    <changefreq>weekly</changefreq>
            \\    <priority>{s}</priority>
            \\  </url>
            \\
        , .{ path, priority });
    }

    return buf.toOwnedSlice(allocator);
}
