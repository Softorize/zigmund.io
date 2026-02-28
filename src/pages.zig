const std = @import("std");
const zigmund = @import("zigmund");

pub fn home(_: *zigmund.Request, _: std.mem.Allocator) !zigmund.Response {
    return zigmund.Response.html(homepage_html);
}

const homepage_html =
    \\<!DOCTYPE html>
    \\<html lang="en">
    \\<head>
    \\  <meta charset="UTF-8">
    \\  <meta name="viewport" content="width=device-width, initial-scale=1.0">
    \\  <title>Zigmund - A FastAPI-inspired Web Framework for Zig</title>
    \\  <meta name="description" content="Zigmund is a FastAPI-inspired web framework for Zig. Build fast, type-safe HTTP APIs with compile-time guarantees.">
    \\  <meta name="robots" content="index, follow">
    \\  <link rel="canonical" href="https://zigmund.io/">
    \\  <meta name="theme-color" content="#0d1117">
    \\  <!-- Open Graph -->
    \\  <meta property="og:type" content="website">
    \\  <meta property="og:url" content="https://zigmund.io/">
    \\  <meta property="og:title" content="Zigmund — FastAPI-inspired Web Framework for Zig">
    \\  <meta property="og:description" content="Build fast, type-safe HTTP APIs with compile-time guarantees. FastAPI patterns meet Zig performance.">
    \\  <meta property="og:site_name" content="Zigmund">
    \\  <meta property="og:image" content="https://zigmund.io/static/img/og-image.png">
    \\  <meta property="og:image:width" content="1200">
    \\  <meta property="og:image:height" content="630">
    \\  <!-- Twitter Card -->
    \\  <meta name="twitter:card" content="summary_large_image">
    \\  <meta name="twitter:title" content="Zigmund — FastAPI-inspired Web Framework for Zig">
    \\  <meta name="twitter:description" content="Build fast, type-safe HTTP APIs with compile-time guarantees. FastAPI patterns meet Zig performance.">
    \\  <meta name="twitter:image" content="https://zigmund.io/static/img/og-image.png">
    \\  <link rel="preconnect" href="https://fonts.googleapis.com">
    \\  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    \\  <link href="https://fonts.googleapis.com/css2?family=VT323&family=IBM+Plex+Mono:wght@400;500;600&display=swap" rel="stylesheet">
    \\  <link rel="stylesheet" href="/static/css/style.css">
    \\  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'><text y='14' font-size='14'>⚡</text></svg>">
    \\  <script type="application/ld+json">
    \\  {
    \\    "@context": "https://schema.org",
    \\    "@graph": [
    \\      {
    \\        "@type": "WebSite",
    \\        "@id": "https://zigmund.io/#website",
    \\        "url": "https://zigmund.io/",
    \\        "name": "Zigmund",
    \\        "description": "A FastAPI-inspired web framework for Zig"
    \\      },
    \\      {
    \\        "@type": "SoftwareSourceCode",
    \\        "@id": "https://zigmund.io/#software",
    \\        "name": "Zigmund",
    \\        "description": "A FastAPI-inspired web framework for Zig. Build fast, type-safe HTTP APIs with compile-time guarantees.",
    \\        "url": "https://zigmund.io/",
    \\        "codeRepository": "https://github.com/Softorize/zigmund",
    \\        "programmingLanguage": "Zig",
    \\        "license": "https://opensource.org/licenses/MIT",
    \\        "author": {
    \\          "@type": "Organization",
    \\          "name": "Softorize",
    \\          "url": "https://github.com/Softorize"
    \\        }
    \\      }
    \\    ]
    \\  }
    \\  </script>
    \\</head>
    \\<body>
    \\
    \\  <!-- Scanline overlay -->
    \\  <div class="scanlines"></div>
    \\
    \\  <!-- Navigation -->
    \\  <nav class="nav">
    \\    <div class="nav-inner">
    \\      <a href="/" class="nav-logo">
    \\        <span class="logo-icon">⚡</span>
    \\        <span class="logo-text">zigmund</span>
    \\        <span class="logo-ver">v0.1.0</span>
    \\      </a>
    \\      <div class="nav-links">
    \\        <a href="#features">Features</a>
    \\        <a href="#quickstart">Quick Start</a>
    \\        <a href="https://github.com/Softorize/zigmund" target="_blank" rel="noopener">
    \\          GitHub
    \\          <span class="ext-icon">↗</span>
    \\        </a>
    \\      </div>
    \\    </div>
    \\  </nav>
    \\
    \\  <!-- Hero -->
    \\  <section class="hero">
    \\    <div class="container">
    \\      <div class="terminal-window">
    \\        <div class="terminal-bar">
    \\          <div class="terminal-buttons">
    \\            <span class="tbtn tbtn-close"></span>
    \\            <span class="tbtn tbtn-min"></span>
    \\            <span class="tbtn tbtn-max"></span>
    \\          </div>
    \\          <div class="terminal-title">zigmund@localhost: ~</div>
    \\          <div class="terminal-bar-right"></div>
    \\        </div>
    \\        <div class="terminal-body">
    \\          <pre class="ascii-art">
    \\ ███████╗██╗ ██████╗ ███╗   ███╗██╗   ██╗███╗   ██╗██████╗
    \\ ╚══███╔╝██║██╔════╝ ████╗ ████║██║   ██║████╗  ██║██╔══██╗
    \\   ███╔╝ ██║██║  ███╗██╔████╔██║██║   ██║██╔██╗ ██║██║  ██║
    \\  ███╔╝  ██║██║   ██║██║╚██╔╝██║██║   ██║██║╚██╗██║██║  ██║
    \\ ███████╗██║╚██████╔╝██║ ╚═╝ ██║╚██████╔╝██║ ╚████║██████╔╝
    \\ ╚══════╝╚═╝ ╚═════╝ ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝
    \\</pre>
    \\          <p class="terminal-tagline"><span class="prompt-user">zigmund</span><span class="prompt-at">@</span><span class="prompt-host">dev</span><span class="prompt-colon">:</span><span class="prompt-path">~</span><span class="prompt-dollar">$</span> <span class="typing">A FastAPI-inspired web framework for Zig_</span></p>
    \\        </div>
    \\      </div>
    \\      <h1 class="hero-title">A FastAPI-inspired Web Framework for Zig</h1>
    \\      <div class="hero-actions">
    \\        <a href="#quickstart" class="btn btn-primary">
    \\          <span class="btn-icon">▶</span> Get Started
    \\        </a>
    \\        <a href="https://github.com/Softorize/zigmund" target="_blank" rel="noopener" class="btn btn-secondary">
    \\          <span class="btn-icon">◆</span> View Source
    \\        </a>
    \\      </div>
    \\      <p class="hero-sub">Open source · MIT License · Zig 0.15.2</p>
    \\    </div>
    \\  </section>
    \\
    \\  <!-- Features -->
    \\  <section id="features" class="features">
    \\    <div class="container">
    \\      <h2 class="section-title">
    \\        <span class="title-deco">───</span>
    \\        <span class="title-bracket">[</span> FEATURES <span class="title-bracket">]</span>
    \\        <span class="title-deco">───</span>
    \\      </h2>
    \\      <div class="features-grid">
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">⚡</div>
    \\          <h3>FastAPI Patterns</h3>
    \\          <p>Familiar API design inspired by Python's FastAPI. Typed parameter extraction, dependency injection, and automatic validation.</p>
    \\        </div>
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">🔒</div>
    \\          <h3>Type-Safe Routes</h3>
    \\          <p>Compile-time route validation with typed query, path, header, and body parameters. Catch errors before they reach production.</p>
    \\        </div>
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">📋</div>
    \\          <h3>OpenAPI 3.1</h3>
    \\          <p>Automatic OpenAPI spec generation with embedded Swagger UI and ReDoc. Your API documentation stays in sync with your code.</p>
    \\        </div>
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">🧩</div>
    \\          <h3>Middleware Pipeline</h3>
    \\          <p>Composable middleware for CORS, rate limiting, compression, sessions, and CSRF protection. Build your own with simple hooks.</p>
    \\        </div>
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">🔐</div>
    \\          <h3>Security Built-in</h3>
    \\          <p>First-class support for OAuth2, HTTP Bearer, API keys, and HTTP Basic auth. Security scheme scaffolding included.</p>
    \\        </div>
    \\
    \\        <div class="feature-card">
    \\          <div class="feature-icon">🧪</div>
    \\          <h3>TestClient</h3>
    \\          <p>In-process test client for fast, deterministic testing. No network overhead &mdash; test your handlers directly.</p>
    \\        </div>
    \\
    \\      </div>
    \\    </div>
    \\  </section>
    \\
    \\  <!-- Quick Start -->
    \\  <section id="quickstart" class="quickstart">
    \\    <div class="container">
    \\      <h2 class="section-title">
    \\        <span class="title-deco">───</span>
    \\        <span class="title-bracket">[</span> QUICK START <span class="title-bracket">]</span>
    \\        <span class="title-deco">───</span>
    \\      </h2>
    \\
    \\      <div class="steps">
    \\        <div class="step">
    \\          <div class="step-number">01</div>
    \\          <div class="step-content">
    \\            <h3>Add dependency</h3>
    \\            <div class="code-window">
    \\              <div class="code-bar">
    \\                <div class="code-bar-dots">
    \\                  <span class="cdot cdot-close"></span>
    \\                  <span class="cdot cdot-min"></span>
    \\                  <span class="cdot cdot-max"></span>
    \\                </div>
    \\                <span class="code-bar-title">build.zig.zon</span>
    \\              </div>
    \\              <pre class="code-body"><span class="c-keyword">.dependencies</span> = .{
    \\    <span class="c-keyword">.zigmund</span> = .{
    \\        <span class="c-keyword">.url</span> = <span class="c-string">"https://github.com/Softorize/zigmund/archive/main.tar.gz"</span>,
    \\    },
    \\},</pre>
    \\            </div>
    \\          </div>
    \\        </div>
    \\
    \\        <div class="step">
    \\          <div class="step-number">02</div>
    \\          <div class="step-content">
    \\            <h3>Write your app</h3>
    \\            <div class="code-window">
    \\              <div class="code-bar">
    \\                <div class="code-bar-dots">
    \\                  <span class="cdot cdot-close"></span>
    \\                  <span class="cdot cdot-min"></span>
    \\                  <span class="cdot cdot-max"></span>
    \\                </div>
    \\                <span class="code-bar-title">src/main.zig</span>
    \\              </div>
    \\              <pre class="code-body"><span class="c-keyword">const</span> std = <span class="c-builtin">@import</span>(<span class="c-string">"std"</span>);
    \\<span class="c-keyword">const</span> zigmund = <span class="c-builtin">@import</span>(<span class="c-string">"zigmund"</span>);
    \\
    \\<span class="c-keyword">pub fn</span> <span class="c-fn">main</span>() !<span class="c-keyword">void</span> {
    \\    <span class="c-keyword">var</span> gpa = std.heap.GeneralPurposeAllocator(.{}){};
    \\    <span class="c-keyword">defer</span> _ = gpa.deinit();
    \\    <span class="c-keyword">const</span> alloc = gpa.allocator();
    \\
    \\    <span class="c-keyword">var</span> app = <span class="c-keyword">try</span> zigmund.App.init(alloc, .{
    \\        .title = <span class="c-string">"My API"</span>,
    \\        .version = <span class="c-string">"0.1.0"</span>,
    \\    });
    \\    <span class="c-keyword">defer</span> app.deinit();
    \\
    \\    <span class="c-keyword">try</span> app.get(<span class="c-string">"/"</span>, hello, .{});
    \\    <span class="c-keyword">try</span> app.serve(.{ .port = <span class="c-number">8000</span> });
    \\}
    \\
    \\<span class="c-keyword">fn</span> <span class="c-fn">hello</span>(
    \\    _: *zigmund.Request,
    \\    alloc: std.mem.Allocator,
    \\) !zigmund.Response {
    \\    <span class="c-keyword">return</span> zigmund.Response.json(alloc, .{
    \\        .message = <span class="c-string">"Hello, World!"</span>,
    \\    });
    \\}</pre>
    \\            </div>
    \\          </div>
    \\        </div>
    \\
    \\        <div class="step">
    \\          <div class="step-number">03</div>
    \\          <div class="step-content">
    \\            <h3>Run it</h3>
    \\            <div class="code-window">
    \\              <div class="code-bar">
    \\                <div class="code-bar-dots">
    \\                  <span class="cdot cdot-close"></span>
    \\                  <span class="cdot cdot-min"></span>
    \\                  <span class="cdot cdot-max"></span>
    \\                </div>
    \\                <span class="code-bar-title">terminal</span>
    \\              </div>
    \\              <pre class="code-body"><span class="c-comment">$ zig build run</span>
    \\<span class="c-string">INFO</span>  Zigmund v0.1.0 serving on http://0.0.0.0:8000
    \\<span class="c-string">INFO</span>  OpenAPI docs at http://0.0.0.0:8000/docs</pre>
    \\            </div>
    \\          </div>
    \\        </div>
    \\      </div>
    \\    </div>
    \\  </section>
    \\
    \\  <!-- Why Zigmund -->
    \\  <section class="why">
    \\    <div class="container">
    \\      <h2 class="section-title">
    \\        <span class="title-deco">───</span>
    \\        <span class="title-bracket">[</span> WHY ZIGMUND <span class="title-bracket">]</span>
    \\        <span class="title-deco">───</span>
    \\      </h2>
    \\      <div class="why-grid">
    \\        <div class="why-card">
    \\          <div class="why-header">
    \\            <span class="why-prompt">~$</span> PERFORMANCE
    \\          </div>
    \\          <p>Zig compiles to native code with no runtime overhead. No garbage collector, no hidden allocations. Your API serves requests at wire speed.</p>
    \\        </div>
    \\        <div class="why-card">
    \\          <div class="why-header">
    \\            <span class="why-prompt">~$</span> FAMILIAR API
    \\          </div>
    \\          <p>If you know FastAPI, you already know Zigmund. Same patterns, same developer experience &mdash; powered by Zig's compile-time safety.</p>
    \\        </div>
    \\        <div class="why-card">
    \\          <div class="why-header">
    \\            <span class="why-prompt">~$</span> SINGLE BINARY
    \\          </div>
    \\          <p>Deploy a single static binary. No interpreters, no virtual machines, no container runtimes required. Just scp and run.</p>
    \\        </div>
    \\      </div>
    \\    </div>
    \\  </section>
    \\
    \\  <!-- Footer -->
    \\  <footer class="footer">
    \\    <div class="container">
    \\      <div class="footer-inner">
    \\        <div class="footer-brand">
    \\          <span class="logo-icon">⚡</span> zigmund
    \\        </div>
    \\        <div class="footer-links">
    \\          <a href="https://github.com/Softorize/zigmund" target="_blank" rel="noopener">GitHub</a>
    \\          <a href="https://github.com/Softorize/zigmund/issues" target="_blank" rel="noopener">Issues</a>
    \\          <a href="https://github.com/Softorize" target="_blank" rel="noopener">Softorize</a>
    \\        </div>
    \\        <div class="footer-copy">
    \\          <span class="blink">█</span> MIT License &middot; Built with Zigmund
    \\        </div>
    \\      </div>
    \\    </div>
    \\  </footer>
    \\
    \\</body>
    \\</html>
;
