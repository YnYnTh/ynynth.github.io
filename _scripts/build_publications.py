#!/usr/bin/env python3
"""Generate the publications list from publications.bib.

Quarto runs this as a pre-render step (see `project: pre-render` in
_quarto.yml), so it also runs in GitHub Actions — push a new .bib and the
page updates without rendering locally first.

    reads   publications.bib, apa.csl
    writes  _generated/publications.md   (pulled in by publications.qmd)

APA formatting is delegated to Pandoc + the APA CSL style, so reference
strings come from the citation processor rather than being hand-assembled
here. This script only adds grouping, ordering, name emphasis, and the
link buttons.

Standard library only, deliberately: nothing to pip install, and CI needs
no Python setup beyond the interpreter it already has.
"""

from __future__ import annotations

import html
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BIB = ROOT / "publications.bib"
CSL = ROOT / "apa.csl"
OUT = ROOT / "_generated" / "publications.md"

# EDIT: name forms to bold in the reference list. APA renders authors as
# "Tang, Y." — add any variants you publish under (maiden name, full given
# name, transliteration differences).
MY_NAMES = ["Tang, Y.", "Tang, Yingying"]

# Section headings, in the order they appear on the page, keyed by CSL type.
SECTIONS: list[tuple[str, tuple[str, ...]]] = [
    ("Journal articles", ("article-journal",)),
    ("Preprints & manuscripts under review", ("article", "manuscript", "unpublished")),
    ("Book chapters", ("chapter",)),
    ("Books", ("book",)),
    ("Conference presentations", ("paper-conference", "speech")),
    ("Data & software", ("dataset", "software")),
    ("Theses", ("thesis",)),
]
OTHER_HEADING = "Other"

# Recognised keys in a Zotero "Extra" field (exported by Better BibTeX into
# the bib `note` field), and the button label each one gets.
LINK_LABELS = {
    "pdf": "PDF",
    "preprint": "Preprint",
    "data": "Data",
    "code": "Code",
    "materials": "Materials",
    "supplement": "Supplement",
    "slides": "Slides",
    "poster": "Poster",
    "osf": "OSF",
}
LINK_ORDER = list(LINK_LABELS)

# `section: Conference presentations` in Zotero's Extra field forces an entry
# into a given section, overriding the CSL-type mapping below. Worth having:
# Zotero item types map onto CSL types in ways that are not always obvious.
NOTE_KEYS = LINK_ORDER + ["section"]
_KEY_ALT = "|".join(NOTE_KEYS)

# Pandoc folds multi-line bib fields onto one line, so pairs cannot be found
# line by line. Match each key and run its value up to the next known key.
NOTE_PAIR_RE = re.compile(
    rf"\b({_KEY_ALT})\s*[:=]\s*(.*?)(?=\s*\b(?:{_KEY_ALT})\s*[:=]|$)",
    re.IGNORECASE | re.DOTALL,
)


def fail(msg: str) -> None:
    sys.exit(f"build_publications.py: {msg}")


def find_pandoc() -> list[str]:
    """Locate Pandoc.

    Quarto bundles its own copy and exports QUARTO_BIN_PATH while running
    scripts, so prefer that: it guarantees the same version locally and in CI.
    """
    bin_path = os.environ.get("QUARTO_BIN_PATH")
    if bin_path:
        candidate = Path(bin_path) / ("pandoc.exe" if os.name == "nt" else "pandoc")
        if candidate.exists():
            return [str(candidate)]

    for name in ("pandoc", "quarto"):
        found = shutil.which(name)
        if found:
            return [found, "pandoc"] if name == "quarto" else [found]

    fail("could not find pandoc (expected it via QUARTO_BIN_PATH or on PATH)")
    raise AssertionError("unreachable")


def run(cmd: list[str], **kwargs) -> subprocess.CompletedProcess:
    try:
        return subprocess.run(
            cmd, check=True, capture_output=True, text=True, **kwargs
        )
    except subprocess.CalledProcessError as exc:
        fail(f"command failed: {' '.join(cmd)}\n{exc.stderr.strip()}")
        raise AssertionError("unreachable")


def read_metadata(pandoc: list[str]) -> list[dict]:
    """Convert the .bib to CSL JSON so we get types, years and notes.

    Better BibTeX can export either BibTeX or BibLaTeX; try the stricter
    reader first and fall back.
    """
    for fmt in ("biblatex", "bibtex"):
        proc = subprocess.run(
            pandoc + [str(BIB), "-f", fmt, "-t", "csljson"],
            capture_output=True,
            text=True,
        )
        if proc.returncode == 0 and proc.stdout.strip():
            try:
                return json.loads(proc.stdout)
            except json.JSONDecodeError:
                continue
    fail(f"could not parse {BIB.name} as BibTeX or BibLaTeX")
    raise AssertionError("unreachable")


def format_entries(pandoc: list[str]) -> dict[str, str]:
    """Render every bib entry through the APA CSL style.

    One Pandoc pass over a stub document with `nocite: @*` produces the whole
    bibliography as HTML, with each entry in a div keyed by its citation key.
    """
    stub = "---\nnocite: |\n  @*\n---\n"
    with tempfile.NamedTemporaryFile(
        "w", suffix=".md", delete=False, encoding="utf-8"
    ) as handle:
        handle.write(stub)
        stub_path = handle.name

    try:
        proc = run(
            pandoc
            + [
                stub_path,
                "--citeproc",
                f"--bibliography={BIB}",
                f"--csl={CSL}",
                "-t",
                "html",
            ]
        )
    finally:
        os.unlink(stub_path)

    pattern = re.compile(
        r'<div id="ref-(?P<key>[^"]+)"[^>]*class="[^"]*csl-entry[^"]*"[^>]*>'
        r"(?P<body>.*?)</div>",
        re.DOTALL,
    )
    return {
        m.group("key"): m.group("body").strip() for m in pattern.finditer(proc.stdout)
    }


def emphasise_name(body: str) -> str:
    """Bold the author's own name in a rendered reference.

    Longest variant first, so "Tang, Yingying" is matched before "Tang, Y."
    The final pass collapses any nesting if two variants happen to overlap.
    """
    for name in sorted(MY_NAMES, key=len, reverse=True):
        escaped = html.escape(name)
        body = body.replace(escaped, f"<strong>{escaped}</strong>")
    body = re.sub(r"(?:<strong>)+", "<strong>", body)
    return re.sub(r"(?:</strong>)+", "</strong>", body)


def parse_note(note: str) -> tuple[list[tuple[str, str]], str | None]:
    """Pull `key: value` pairs out of a Zotero Extra / bib note field.

    Returns the link buttons in display order, plus any section override.
    Prose in the field that isn't a recognised key is ignored.
    """
    found: dict[str, str] = {}
    for match in NOTE_PAIR_RE.finditer(note):
        value = match.group(2).strip().rstrip(";,")
        if value:
            found[match.group(1).lower()] = value

    links = [(LINK_LABELS[k], found[k]) for k in LINK_ORDER if k in found]
    return links, found.get("section")


def year_of(item: dict) -> int:
    """Publication year, or 9999 for undated work so it sorts to the top."""
    parts = item.get("issued", {}).get("date-parts") or [[]]
    if parts and parts[0]:
        try:
            return int(parts[0][0])
        except (TypeError, ValueError):
            pass
    return 9999


def section_for(csl_type: str) -> str:
    for heading, types in SECTIONS:
        if csl_type in types:
            return heading
    return OTHER_HEADING


def render(items: list[dict], formatted: dict[str, str]) -> str:
    grouped: dict[str, list[tuple[int, str, str]]] = {}

    for item in items:
        key = item.get("id")
        body = formatted.get(key)
        if not body:
            print(
                f"build_publications.py: no rendered entry for '{key}', skipping",
                file=sys.stderr,
            )
            continue

        links, section_override = parse_note(item.get("note", "") or "")
        block = ['<div class="entry">', emphasise_name(body)]
        if links:
            anchors = " ".join(
                f'<a href="{html.escape(url, quote=True)}">{label}</a>'
                for label, url in links
            )
            block.append(f'<div class="entry-links">{anchors}</div>')
        block.append("</div>")

        heading = section_override or section_for(item.get("type", ""))
        grouped.setdefault(heading, []).append(
            (year_of(item), body, "\n".join(block))
        )

    # Known sections keep their fixed order; any section introduced by a
    # `section:` override is appended, then the catch-all last.
    known = [h for h, _ in SECTIONS]
    extra = [h for h in grouped if h not in known and h != OTHER_HEADING]
    order = known + sorted(extra) + [OTHER_HEADING]
    out: list[str] = []
    for heading in order:
        entries = grouped.get(heading)
        if not entries:
            continue
        # Year descending; the CSL style has already alphabetised within year.
        entries.sort(key=lambda e: (-e[0], e[1]))
        out.append(f"## {heading}\n")
        out.extend(entry for _, _, entry in entries)
        out.append("")

    if not out:
        return (
            "*No publications found. Add entries to `publications.bib` — see "
            "the README for the Zotero auto-export setup.*\n"
        )
    return "\n".join(out)


def main() -> None:
    if not BIB.exists():
        fail(f"{BIB.name} not found")
    if not CSL.exists():
        fail(f"{CSL.name} not found (copy it from ~/Zotero/styles/apa.csl)")

    pandoc = find_pandoc()
    items = read_metadata(pandoc)
    formatted = format_entries(pandoc)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(render(items, formatted), encoding="utf-8")
    print(f"build_publications.py: wrote {len(items)} entries to {OUT.name}")


if __name__ == "__main__":
    main()
