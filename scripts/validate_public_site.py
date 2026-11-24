from __future__ import annotations

import json
import posixpath
import re
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(".")
BASE_URL = "https://anasgdxj.github.io/darb-delivery-platform/"
PAGES = [
    "index.html",
    "en/index.html",
    "tr/index.html",
    "faq/index.html",
    "drivers/index.html",
    "merchants/index.html",
    "privacy/index.html",
    "terms/index.html",
]
ERRORS: list[str] = []


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tags: list[tuple[str, dict[str, str | None]]] = []
        self.ids: set[str] = set()
        self.duplicate_ids: set[str] = set()
        self.h1_count = 0
        self.title_count = 0
        self.title_text = ""
        self.in_title = False
        self.json_ld: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        data = dict(attrs)
        self.tags.append((tag, data))
        if tag == "h1":
            self.h1_count += 1
        if tag == "title":
            self.title_count += 1
            self.in_title = True
        if data.get("id"):
            value = str(data["id"])
            if value in self.ids:
                self.duplicate_ids.add(value)
            self.ids.add(value)
        if tag == "script" and data.get("type") == "application/ld+json":
            self.json_ld.append("")

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_text += data


def fail(message: str) -> None:
    ERRORS.append(message)


def local_target(page: str, raw_url: str) -> tuple[str | None, str]:
    parsed = urlsplit(raw_url)
    if parsed.scheme or parsed.netloc or raw_url.startswith(("mailto:", "tel:", "data:", "javascript:")):
        return None, ""
    target = parsed.path
    if not target:
        return page, parsed.fragment
    if target.startswith("/"):
        target = target.lstrip("/")
    else:
        target = posixpath.join(posixpath.dirname(page), target)
    target = posixpath.normpath(target)
    if target in ("", "."):
        target = "index.html"
    if target.endswith("/"):
        target += "index.html"
    elif not posixpath.splitext(target)[1]:
        target = posixpath.join(target, "index.html")
    return target, parsed.fragment


titles: set[str] = set()
for page in PAGES:
    path = ROOT / page
    if not path.is_file():
        fail(f"Missing public page: {page}")
        continue

    source = path.read_text(encoding="utf-8")
    parser = PageParser()
    parser.feed(source)

    html_tag = next((attrs for tag, attrs in parser.tags if tag == "html"), {})
    if not html_tag.get("lang") or not html_tag.get("dir"):
        fail(f"{page}: missing html lang/dir")
    if not any(tag == "meta" and attrs.get("name") == "viewport" for tag, attrs in parser.tags):
        fail(f"{page}: missing viewport")
    if not any(tag == "meta" and attrs.get("name") == "description" and attrs.get("content") for tag, attrs in parser.tags):
        fail(f"{page}: missing meta description")
    if not any(tag == "link" and attrs.get("rel") == "canonical" for tag, attrs in parser.tags):
        fail(f"{page}: missing canonical URL")
    if not any(tag == "meta" and attrs.get("property") == "og:title" for tag, attrs in parser.tags):
        fail(f"{page}: missing Open Graph title")
    if not any(tag == "meta" and attrs.get("name") == "twitter:card" for tag, attrs in parser.tags):
        fail(f"{page}: missing Twitter card metadata")
    if page in {"privacy/index.html", "terms/index.html"}:
        if not any(tag == "meta" and attrs.get("name") == "robots" and attrs.get("content") == "noindex,follow" for tag, attrs in parser.tags):
            fail(f"{page}: draft legal page must be noindex until reviewed")
    if not any(tag == "meta" and attrs.get("http-equiv", "").lower() == "content-security-policy" for tag, attrs in parser.tags):
        fail(f"{page}: missing Content-Security-Policy")
    if parser.title_count != 1 or not parser.title_text.strip():
        fail(f"{page}: expected exactly one non-empty title")
    title = parser.title_text.strip()
    if title in titles:
        fail(f"{page}: duplicate title: {title}")
    titles.add(title)
    if parser.h1_count != 1:
        fail(f"{page}: expected exactly one h1, found {parser.h1_count}")
    if parser.duplicate_ids:
        fail(f"{page}: duplicate ids: {sorted(parser.duplicate_ids)}")

    for tag, attrs in parser.tags:
        if tag == "img" and attrs.get("alt") is None:
            fail(f"{page}: image missing alt attribute")
        if tag == "button" and attrs.get("type") not in {"button", "submit", "reset"}:
            fail(f"{page}: button missing explicit type")
        if attrs.get("target") == "_blank":
            rel = set((attrs.get("rel") or "").lower().split())
            if not {"noopener", "noreferrer"}.issubset(rel):
                fail(f"{page}: target=_blank link missing rel=noopener noreferrer")

        raw_url = attrs.get("href") if tag in {"a", "link"} else attrs.get("src") if tag in {"script", "img"} else None
        if not raw_url:
            continue
        destination, fragment = local_target(page, str(raw_url))
        if destination is None:
            continue
        target_path = ROOT / destination
        if not target_path.is_file():
            fail(f"{page}: broken local {tag} URL {raw_url} -> {destination}")
            continue
        if fragment:
            target_source = target_path.read_text(encoding="utf-8")
            if not re.search(r'\bid=["\']' + re.escape(fragment) + r'["\']', target_source):
                fail(f"{page}: broken fragment {raw_url}")

# Validate required assets and exact Google Search Console verification payload.
for asset in [
    "assets/css/site.css",
    "assets/css/pages.css",
    "assets/js/site.js",
    "assets/favicon.svg",
    "robots.txt",
    "sitemap.xml",
    "site.webmanifest",
    "google3dcfcc43ffdf1742.html",
]:
    if not (ROOT / asset).is_file():
        fail(f"Missing required asset: {asset}")

verification = ROOT / "google3dcfcc43ffdf1742.html"
if verification.is_file():
    expected = "google-site-verification: google3dcfcc43ffdf1742.html"
    if verification.read_text(encoding="utf-8").strip() != expected:
        fail("Google Search Console verification file has unexpected content")

robots = (ROOT / "robots.txt").read_text(encoding="utf-8")
if f"Sitemap: {BASE_URL}sitemap.xml" not in robots:
    fail("robots.txt does not reference the canonical sitemap")

try:
    sitemap = ET.parse(ROOT / "sitemap.xml").getroot()
    ns = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    sitemap_urls = {
        item.text for item in sitemap.findall("sm:url/sm:loc", ns)
    }
    expected_urls = {
        BASE_URL,
        *(BASE_URL + page.rsplit("/", 1)[0] + "/" for page in PAGES if "/" in page and page not in {"privacy/index.html", "terms/index.html"}),
    }
    if not expected_urls.issubset(sitemap_urls):
        fail("sitemap.xml is missing one or more indexable public page URLs")
    for legal_path in ("privacy/index.html", "terms/index.html"):
        legal_url = BASE_URL + legal_path.rsplit("/", 1)[0] + "/"
        if legal_url in sitemap_urls:
            fail(f"Draft legal page must not appear in sitemap: {legal_path}")
except (ET.ParseError, OSError) as exc:
    fail(f"Invalid sitemap.xml: {exc}")

try:
    manifest = json.loads((ROOT / "site.webmanifest").read_text(encoding="utf-8"))
    if manifest.get("start_url") != "./" or manifest.get("scope") != "./":
        fail("site.webmanifest must use relative start_url and scope")
    for icon in manifest.get("icons", []):
        icon_path = icon.get("src", "")
        if icon_path and not (ROOT / icon_path.removeprefix("./")).is_file():
            fail(f"Missing webmanifest icon: {icon_path}")
except (json.JSONDecodeError, OSError) as exc:
    fail(f"Invalid site.webmanifest: {exc}")

if ERRORS:
    print("Public website validation failed:")
    for error in ERRORS:
        print(f" - {error}")
    sys.exit(1)

print(f"Validated {len(PAGES)} public pages, internal links, accessibility basics, SEO metadata, sitemap, manifest, and Google verification file.")
