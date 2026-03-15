#!/usr/bin/env python3
"""Build documentation: convert markdown files to HTML fragments + generate manifest and search index."""

import json
import os
import re
import sys

try:
    import markdown
except ImportError:
    print("Installing markdown package...")
    os.system(f"{sys.executable} -m pip install markdown")
    import markdown

DOCS_SRC = os.path.join(os.path.dirname(__file__), "..", "vendor", "zigmund", "docs")
DOCS_OUT = os.path.join(os.path.dirname(__file__), "..", "content", "docs")

# Sections and their display metadata
SECTIONS = {
    "tutorial": {"title": "Tutorial", "icon": "▶", "description": "Step-by-step guides covering all framework features."},
    "reference": {"title": "Reference", "icon": "◆", "description": "Complete API reference for every public type and function."},
    "advanced": {"title": "Advanced", "icon": "⚡", "description": "Advanced features and patterns for experienced users."},
    "how-to": {"title": "How-To", "icon": "◇", "description": "Quick recipes for common tasks."},
    "zig-guide": {"title": "Zig Guide", "icon": "⬡", "description": "Zig concepts for developers from other languages."},
    "deployment": {"title": "Deployment", "icon": "▲", "description": "Docker, production config, TLS, and cloud deployment."},
}

# Top-level pages (not in a section directory)
TOP_LEVEL_PAGES = ["installation", "changelog", "contributing"]


def slugify(text):
    """Convert a heading to a URL-friendly slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    return text.strip('-')


def extract_title(md_content):
    """Extract the first H1 heading from markdown content."""
    for line in md_content.split('\n'):
        line = line.strip()
        if line.startswith('# ') and not line.startswith('## '):
            return line[2:].strip()
    return None


def extract_headings(md_content):
    """Extract all headings for search index."""
    headings = []
    for line in md_content.split('\n'):
        line = line.strip()
        m = re.match(r'^(#{1,4})\s+(.+)$', line)
        if m:
            headings.append(m.group(2).strip())
    return headings


def extract_first_paragraph(md_content):
    """Extract first meaningful paragraph for search description."""
    lines = md_content.split('\n')
    paragraph = []
    in_paragraph = False
    for line in lines:
        stripped = line.strip()
        # Skip headings, empty lines, code blocks, front matter
        if stripped.startswith('#') or stripped.startswith('```') or stripped.startswith('---'):
            if in_paragraph:
                break
            continue
        if not stripped:
            if in_paragraph:
                break
            continue
        # Skip links-only lines (like index pages)
        if stripped.startswith('- ['):
            continue
        in_paragraph = True
        paragraph.append(stripped)
    return ' '.join(paragraph)[:200]


def highlight_zig_code(html_content):
    """Apply syntax highlighting CSS classes to Zig code blocks."""
    def highlight_block(match):
        code = match.group(1)

        # Keywords
        zig_keywords = [
            'const', 'var', 'pub', 'fn', 'return', 'try', 'catch', 'if', 'else',
            'while', 'for', 'switch', 'break', 'continue', 'defer', 'errdefer',
            'struct', 'enum', 'union', 'error', 'void', 'bool', 'true', 'false',
            'null', 'undefined', 'unreachable', 'comptime', 'inline', 'test',
            'orelse', 'and', 'or', 'not', 'anytype', 'type', 'noreturn',
            'threadlocal', 'align', 'packed', 'extern', 'export', 'async',
            'await', 'suspend', 'resume', 'nosuspend', 'usingnamespace',
        ]

        # Builtins
        zig_builtins = [
            '@import', '@intCast', '@truncate', '@bitCast', '@ptrCast',
            '@alignCast', '@enumFromInt', '@intFromEnum', '@typeInfo',
            '@typeName', '@hasField', '@field', '@sizeOf', '@alignOf',
            '@as', '@This', '@errorName', '@tagName', '@src',
        ]

        # Process the code - escape HTML first, then apply highlights
        # We work on already-escaped HTML since markdown already escapes it
        highlighted = code

        # Comments (// ...)
        highlighted = re.sub(
            r'(//[^\n]*)',
            r'<span class="c-comment">\1</span>',
            highlighted
        )

        # Strings ("...")
        highlighted = re.sub(
            r'(&quot;(?:[^&]|&(?!quot;))*?&quot;)',
            r'<span class="c-string">\1</span>',
            highlighted
        )

        # Multi-line strings (\\...)
        highlighted = re.sub(
            r'(\\\\[^\n]*)',
            r'<span class="c-string">\1</span>',
            highlighted
        )

        # Builtins
        for builtin in zig_builtins:
            highlighted = highlighted.replace(builtin, f'<span class="c-builtin">{builtin}</span>')

        # Numbers
        highlighted = re.sub(
            r'\b(\d+(?:\.\d+)?)\b',
            r'<span class="c-number">\1</span>',
            highlighted
        )

        # Keywords (word boundary match)
        for kw in zig_keywords:
            highlighted = re.sub(
                rf'\b({re.escape(kw)})\b',
                r'<span class="c-keyword">\1</span>',
                highlighted
            )

        return f'<pre><code class="language-zig">{highlighted}</code></pre>'

    # Match <pre><code class="language-zig">...</code></pre> blocks
    html_content = re.sub(
        r'<pre><code class="language-zig">(.*?)</code></pre>',
        highlight_block,
        html_content,
        flags=re.DOTALL
    )

    return html_content


def get_page_order_from_index(index_path):
    """Parse an index.md to extract the page ordering from links."""
    if not os.path.exists(index_path):
        return []
    with open(index_path, 'r') as f:
        content = f.read()
    pages = []
    for match in re.finditer(r'\[([^\]]+)\]\(([^)]+\.md)\)', content):
        link = match.group(2)
        # Remove ../ prefixes and .md suffix
        link = link.replace('../', '')
        if link.endswith('.md'):
            link = link[:-3]
        # Only include direct children (not paths with /)
        if '/' not in link and link != 'index':
            pages.append(link)
    return pages


def build_docs():
    """Main build function."""
    os.makedirs(DOCS_OUT, exist_ok=True)

    md_converter = markdown.Markdown(extensions=[
        'fenced_code',
        'tables',
        'toc',
        'attr_list',
        'def_list',
        'sane_lists',
    ])

    manifest = {
        "sections": {},
        "pages": {},
        "top_level": [],
    }
    search_index = []

    # Process top-level pages
    for page_slug in TOP_LEVEL_PAGES:
        md_path = os.path.join(DOCS_SRC, f"{page_slug}.md")
        if not os.path.exists(md_path):
            continue

        with open(md_path, 'r') as f:
            md_content = f.read()

        title = extract_title(md_content) or page_slug.replace('-', ' ').title()
        md_converter.reset()
        html = md_converter.convert(md_content)
        html = highlight_zig_code(html)

        # Write HTML fragment
        out_path = os.path.join(DOCS_OUT, f"{page_slug}.html")
        with open(out_path, 'w') as f:
            f.write(html)

        doc_path = page_slug
        manifest["pages"][doc_path] = {
            "title": title,
            "section": None,
            "path": doc_path,
        }
        manifest["top_level"].append(doc_path)

        search_index.append({
            "path": doc_path,
            "title": title,
            "description": extract_first_paragraph(md_content),
            "headings": extract_headings(md_content),
        })

    # Process each section
    for section_slug, section_meta in SECTIONS.items():
        section_dir = os.path.join(DOCS_SRC, section_slug)
        if not os.path.isdir(section_dir):
            continue

        section_out = os.path.join(DOCS_OUT, section_slug)
        os.makedirs(section_out, exist_ok=True)

        # Get page ordering from index.md
        index_path = os.path.join(section_dir, "index.md")
        ordered_pages = get_page_order_from_index(index_path)

        # Find all .md files in section
        all_pages = []
        for fname in sorted(os.listdir(section_dir)):
            if fname.endswith('.md') and fname != 'index.md':
                slug = fname[:-3]
                all_pages.append(slug)

        # Order: explicit order first, then remaining alphabetically
        page_slugs = []
        for slug in ordered_pages:
            if slug in all_pages:
                page_slugs.append(slug)
        for slug in all_pages:
            if slug not in page_slugs:
                page_slugs.append(slug)

        section_pages = []

        for page_slug in page_slugs:
            md_path = os.path.join(section_dir, f"{page_slug}.md")
            if not os.path.exists(md_path):
                continue

            with open(md_path, 'r') as f:
                md_content = f.read()

            title = extract_title(md_content) or page_slug.replace('-', ' ').title()
            md_converter.reset()
            html = md_converter.convert(md_content)
            html = highlight_zig_code(html)

            # Write HTML fragment
            out_path = os.path.join(section_out, f"{page_slug}.html")
            with open(out_path, 'w') as f:
                f.write(html)

            doc_path = f"{section_slug}/{page_slug}"
            manifest["pages"][doc_path] = {
                "title": title,
                "section": section_slug,
                "path": doc_path,
            }
            section_pages.append(doc_path)

            search_index.append({
                "path": doc_path,
                "title": title,
                "section": section_meta["title"],
                "description": extract_first_paragraph(md_content),
                "headings": extract_headings(md_content),
            })

        # Add prev/next links
        for i, doc_path in enumerate(section_pages):
            if i > 0:
                manifest["pages"][doc_path]["prev"] = {
                    "path": section_pages[i - 1],
                    "title": manifest["pages"][section_pages[i - 1]]["title"],
                }
            if i < len(section_pages) - 1:
                manifest["pages"][doc_path]["next"] = {
                    "path": section_pages[i + 1],
                    "title": manifest["pages"][section_pages[i + 1]]["title"],
                }

        manifest["sections"][section_slug] = {
            "title": section_meta["title"],
            "icon": section_meta["icon"],
            "description": section_meta["description"],
            "pages": section_pages,
            "count": len(section_pages),
        }

    # Write manifest
    with open(os.path.join(DOCS_OUT, "_manifest.json"), 'w') as f:
        json.dump(manifest, f, indent=2)

    # Write search index
    with open(os.path.join(DOCS_OUT, "_search_index.json"), 'w') as f:
        json.dump(search_index, f, indent=2)

    # Print summary
    total_pages = len(manifest["pages"])
    print(f"Built {total_pages} documentation pages")
    for slug, sec in manifest["sections"].items():
        print(f"  {sec['title']}: {sec['count']} pages")
    print(f"  Top-level: {len(manifest['top_level'])} pages")
    print(f"Search index: {len(search_index)} entries")


if __name__ == "__main__":
    build_docs()
