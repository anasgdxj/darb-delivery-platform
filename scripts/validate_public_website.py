#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import xml.etree.ElementTree as ET

ROOT = Path.cwd().resolve()
PUBLIC_PAGES = [
    Path("index.html"),
    Path("en/index.html"),
    Path("tr/index.html"),
    Path("app/index.html"),
    Path("faq/index.html"),
    Path("drivers/index.html"),
    Path("merchants/index.html"),
    Path("privacy/index.html"),
    Path("terms/index.html"),
    Path("404.html"),
]
MARKETING_PAGES = {
    Path("index.html"),
    Path("en/index.html"),
    Path("tr/index.html"),
    Path("faq/index.html"),
    Path("drivers/index.html"),
    Path("merchants/index.html"),
    Path("privacy/index.html"),
    Path("terms/index.html"),
}
errors: list[str] = []
parsed: dict[Path, "PageAudit"] = {}

class PageAudit(HTMLParser):
    def __init__(self, path: Path):
        super().__init__(convert_charrefs=True)
        self.path = path
        self.ids: set[str] = set()
        self.references: list[tuple[str, str]] = []
        self.inline_scripts: list[str] = []
        self._script_type: str | None = None
        self._script_parts: list[str] = []
        self.lang: str | None = None
        self.direction: str | None = None
        self.title_parts: list[str] = []
        self.in_title = False
        self.viewport = False
        self.description = False
        self.canonical = False
        self.csp = False
        self.root_seen = False

    def handle_starttag(self, tag: str, attrs):
        a = dict(attrs)
        if tag == "html":
            self.root_seen = True
            self.lang = a.get("lang")
            self.direction = a.get("dir")
        if a.get("id"):
            self.ids.add(a["id"])
        for key in ("href", "src"):
            value = a.get(key)
            if value:
                self.references.append((key, value))
        if tag == "meta":
            name = (a.get("name") or "").lower()
            if name == "viewport":
                self.viewport = True
            if name == "description" and a.get("content", "").strip():
                self.description = True
            if a.get("http-equiv", "").lower() == "content-security-policy":
                self.csp = True
        if tag == "link" and (a.get("rel") or "").lower() == "canonical":
            self.canonical = bool(a.get("href"))
        if tag == "title":
            self.in_title = True
        if tag == "script":
            self._script_type = (a.get("type") or "").lower()
            self._script_parts = []

    def handle_data(self, data: str):
        if self.in_title:
            self.title_parts.append(data)
        if self._script_type is not None and self._script_type != "application/ld+json":
            self._script_parts.append(data)

    def handle_endtag(self, tag: str):
        if tag == "title":
            self.in_title = False
        if tag == "script" and self._script_type is not None:
            code = "".join(self._script_parts).strip()
            if code:
                self.inline_scripts.append(code)
            self._script_type = None
            self._script_parts = []

def fail(message: str):
    errors.append(message)

for page in PUBLIC_PAGES:
    full = ROOT / page
    if not full.is_file():
        fail(f"Missing public page: {page.as_posix()}")
        continue
    audit = PageAudit(page)
    try:
        audit.feed(full.read_text(encoding="utf-8"))
        audit.close()
    except Exception as exc:
        fail(f"Cannot parse {page.as_posix()}: {exc}")
        continue
    parsed[page] = audit
    if not audit.root_seen or not audit.lang or not audit.direction:
        fail(f"{page.as_posix()} must declare html lang and dir")
    if not "".join(audit.title_parts).strip():
        fail(f"{page.as_posix()} is missing a title")
    if not audit.viewport:
        fail(f"{page.as_posix()} is missing the viewport meta tag")
    if page in MARKETING_PAGES:
        if not audit.description:
            fail(f"{page.as_posix()} is missing a meta description")
        if not audit.canonical:
            fail(f"{page.as_posix()} is missing a canonical URL")
        if not audit.csp:
            fail(f"{page.as_posix()} is missing a Content-Security-Policy meta tag")

for page, audit in parsed.items():
    for kind, value in audit.references:
        value = value.strip()
        if not value or value.startswith("#"):
            fragment = value[1:] if value.startswith("#") else ""
            if fragment and fragment not in audit.ids:
                fail(f"Broken anchor in {page.as_posix()}: #{fragment}")
            continue
        parts = urlsplit(value)
        if parts.scheme or parts.netloc or value.startswith("//"):
            continue
        target_path = unquote(parts.path)
        if not target_path:
            target = ROOT / page
        elif target_path.startswith("/"):
            target = ROOT / target_path.lstrip("/")
        else:
            target = (ROOT / page.parent / target_path).resolve()
        if target.is_dir() or target_path.endswith("/"):
            target = target / "index.html"
        if not target.is_file():
            fail(f"Broken local {kind} in {page.as_posix()}: {value}")
            continue
        if parts.fragment and target.suffix.lower() == ".html":
            relative = target.relative_to(ROOT)
            target_page = Path("index.html") if relative.as_posix() == "index.html" else relative
            target_audit = parsed.get(target_page)
            if target_audit is None:
                target_audit = PageAudit(target_page)
                try:
                    target_audit.feed(target.read_text(encoding="utf-8"))
                    target_audit.close()
                except Exception as exc:
                    fail(f"Cannot parse link target {target_page.as_posix()}: {exc}")
                    continue
                parsed[target_page] = target_audit
            if unquote(parts.fragment) not in target_audit.ids:
                fail(f"Broken fragment in {page.as_posix()}: {value}")

js_files = [Path("assets/js/site.js")]
for js_file in js_files:
    if not (ROOT / js_file).is_file():
        fail(f"Missing JavaScript asset: {js_file.as_posix()}")
        continue
    result = subprocess.run(
        ["node", "--check", str(ROOT / js_file)],
        capture_output=True, text=True
    )
    if result.returncode:
        fail(f"JavaScript syntax error in {js_file.as_posix()}: {result.stderr.strip()}")

for page, audit in parsed.items():
    for index, code in enumerate(audit.inline_scripts, start=1):
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8") as handle:
            handle.write(code)
            handle.flush()
            result = subprocess.run(
                ["node", "--check", handle.name],
                capture_output=True, text=True
            )
        if result.returncode:
            fail(f"Inline JavaScript syntax error in {page.as_posix()} script {index}: {result.stderr.strip()}")

root_html = (ROOT / "index.html").read_text(encoding="utf-8")
if "DAZREVO" not in root_html:
    fail("The public home page must use the approved DAZREVO identity")
if "app-debug.apk" in root_html:
    fail("The public home page must never advertise a debug APK")
if "https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk" not in root_html:
    fail("The public home page must link to the official latest signed APK")
if "admin/" in root_html or "بوابة الإدارة" in root_html or "دخول الإدارة" in root_html:
    fail("Admin portal links must not appear on the public home page")

for page in MARKETING_PAGES:
    page_html = (ROOT / page).read_text(encoding="utf-8")
    if 'href="./app/' in page_html or 'href="../app/' in page_html:
        fail(f"{page.as_posix()} must not advertise the unfinished web portal as a live service")

portal_html = (ROOT / "app/index.html").read_text(encoding="utf-8")
if 'class="web-portal-maintenance"' not in portal_html or 'name="robots" content="noindex,nofollow"' not in portal_html:
    fail("The unfinished web portal must remain gated and excluded from search indexing")
if "بوابة الويب قيد الإعداد" not in portal_html:
    fail("The web portal maintenance notice is missing")

not_found_html = ROOT / "404.html"
if not_found_html.is_file():
    fail("Missing DAZREVO-branded 404.html")
else:
    content_404 = not_found_html.read_text(encoding="utf-8")
    if "DAZREVO" not in content_404 or "دَرْب" in content_404:
        fail("404.html must use the current DAZREVO identity, not the retired DARB brand")
    if 'name="robots" content="noindex,nofollow"' not in content_404:
        fail("404.html must be excluded from search indexing")

admin_page = ROOT / "admin-web/index.html"
if not admin_page.is_file():
    fail("Missing public admin portal page")
else:
    admin_html = admin_page.read_text(encoding="utf-8")
    admin_scripts = re.findall(r"<script>(.*?)</script>", admin_html, re.S)
    if len(admin_scripts) != 1:
        fail(f"Expected one inline admin script, found {len(admin_scripts)}")
    else:
        with tempfile.NamedTemporaryFile("w", suffix=".js", encoding="utf-8") as handle:
            handle.write(admin_scripts[0])
            handle.flush()
            result = subprocess.run(["node", "--check", handle.name], capture_output=True, text=True)
        if result.returncode:
            fail(f"Admin portal JavaScript syntax error: {result.stderr.strip()}")
    required_admin_markers = [
        "/admin/delivery-zones",
        "renderZones",
        "/admin/drivers/pending",
        "/admin/vendors/pending",
        "handleGoogleCredential",
    ]
    missing_admin_markers = [item for item in required_admin_markers if item not in admin_html]
    if missing_admin_markers:
        fail("Admin portal is missing required operations: " + ", ".join(missing_admin_markers))

manifest_path = ROOT / "app-update.json"
if not manifest_path.is_file():
    fail("Missing app-update.json; the public site cannot show the current Android release")
else:
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if not isinstance(manifest.get("versionCode"), int) or manifest["versionCode"] < 1:
            fail("app-update.json must contain a positive integer versionCode")
        if not isinstance(manifest.get("versionName"), str) or not manifest["versionName"].strip():
            fail("app-update.json must contain a non-empty versionName")
        if manifest.get("apkUrl") != "https://github.com/anasgdxj/darb-delivery-platform/releases/download/latest/app-release.apk":
            fail("app-update.json must point to the official latest signed APK")
        if not re.fullmatch(r"[0-9a-fA-F]{64}", str(manifest.get("sha256", ""))):
            fail("app-update.json must contain a valid 64-character SHA-256 digest")
        if not isinstance(manifest.get("releaseNotes"), str) or not manifest["releaseNotes"].strip():
            fail("app-update.json must contain release notes")
    except Exception as exc:
        fail(f"Invalid app-update.json: {exc}")

sitemap = ROOT / "sitemap.xml"
if not sitemap.is_file():
    fail("Missing sitemap.xml")
else:
    try:
        tree = ET.parse(sitemap)
        namespace = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
        for node in tree.findall(".//sm:loc", namespace):
            url = (node.text or "").strip()
            path = urlsplit(url).path
            prefix = "/darb-delivery-platform"
            if path.startswith(prefix):
                path = path[len(prefix):]
            local = ROOT / path.lstrip("/")
            if local.is_dir() or path.endswith("/"):
                local = local / "index.html"
            if not local.is_file():
                fail(f"Sitemap URL has no matching public file: {url}")
    except Exception as exc:
        fail(f"Invalid sitemap.xml: {exc}")

if errors:
    print("DAZREVO public website validation failed:")
    for error in errors:
        print(f" - {error}")
    sys.exit(1)

print(f"DAZREVO public website validation passed: {len(PUBLIC_PAGES)} pages, local links, SEO metadata, sitemap, and JavaScript syntax.")
