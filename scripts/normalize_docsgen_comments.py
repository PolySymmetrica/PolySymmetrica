#!/usr/bin/env python3
"""
Rewrite Javadoc-style `/** ... */` blocks into docsgen-friendly line comments.

When a block sits directly on a function or module declaration, emit a docsgen
`// Function:` or `// Module:` block. Otherwise, rewrite the Javadoc as plain
`//` prose so the source tree no longer mixes comment syntaxes.
"""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]


def split_top_level(text: str) -> list[str]:
    items: list[str] = []
    current: list[str] = []
    paren_depth = 0
    bracket_depth = 0
    brace_depth = 0
    in_backticks = False
    in_single_quote = False
    in_double_quote = False
    escaped = False

    for ch in text:
        if escaped:
            current.append(ch)
            escaped = False
            continue

        if (in_single_quote or in_double_quote) and ch == "\\":
            current.append(ch)
            escaped = True
            continue

        if not in_single_quote and not in_double_quote and ch == "`":
            in_backticks = not in_backticks
        elif not in_backticks and ch == "'" and not in_double_quote:
            in_single_quote = not in_single_quote
        elif not in_backticks and ch == '"' and not in_single_quote:
            in_double_quote = not in_double_quote
        elif not in_backticks and not in_single_quote and not in_double_quote:
            if ch == "(":
                paren_depth += 1
            elif ch == ")" and paren_depth > 0:
                paren_depth -= 1
            elif ch == "[":
                bracket_depth += 1
            elif ch == "]" and bracket_depth > 0:
                bracket_depth -= 1
            elif ch == "{":
                brace_depth += 1
            elif ch == "}" and brace_depth > 0:
                brace_depth -= 1
            elif ch == "," and paren_depth == 0 and bracket_depth == 0 and brace_depth == 0:
                item = "".join(current).strip()
                if item:
                    items.append(item)
                current = []
                continue
        current.append(ch)

    tail = "".join(current).strip()
    if tail:
        items.append(tail)
    return items


def extract_block_lines(block_text: str) -> list[str]:
    lines: list[str] = []
    for line in block_text.splitlines():
        stripped = line.strip()
        if stripped.startswith("/**") or stripped == "*/":
            continue
        if stripped.startswith("*"):
            stripped = stripped[1:].lstrip()
        lines.append(stripped)
    return lines


FIELD_ALIASES = {
    "arguments": "Params",
    "args": "Params",
    "limitations": "Limitations/Gotchas",
    "gotchas": "Limitations/Gotchas",
    "limitations/gotchas": "Limitations/Gotchas",
    "notes": "Notes",
    "note": "Notes",
    "example": "Examples",
    "examples": "Examples",
    "quick usage": "Usage",
}

RECOGNIZED_FIELDS = {
    "Function",
    "Module",
    "Params",
    "Returns",
    "Limitations/Gotchas",
    "Notes",
    "Examples",
    "Usage",
    "Description",
    "Approach",
    "Purpose",
}


def normalize_field_name(key: str) -> str:
    stripped = key.strip()
    lowered = stripped.lower()
    if lowered in FIELD_ALIASES:
        return FIELD_ALIASES[lowered]
    return stripped


def parse_block(block_text: str) -> dict[str, list[str]]:
    fields: dict[str, list[str]] = {}
    current_key: str | None = None
    for line in extract_block_lines(block_text):
        if not line:
            if current_key:
                fields.setdefault(current_key, []).append("")
            continue
        match = re.match(r"^([A-Za-z][A-Za-z0-9 /-]*):\s*(.*)$", line)
        if match:
            key = normalize_field_name(match.group(1))
            if key in RECOGNIZED_FIELDS:
                current_key = key
                fields.setdefault(key, []).append(match.group(2).strip())
                continue
            current_key = "Preamble"
            fields.setdefault(current_key, []).append(line.strip())
        elif current_key and current_key not in ("Function", "Module"):
            fields.setdefault(current_key, []).append(line.strip())
        else:
            current_key = "Preamble"
            fields.setdefault(current_key, []).append(line.strip())
    return fields


def extract_declaration(source_text: str, start_index: int) -> tuple[str, str, list[str]] | None:
    tail = source_text[start_index:]
    tail = re.sub(r"^(?:\s|//[^\n]*\n)*", "", tail)
    match = re.match(r"\s*(function|module)\s+([A-Za-z0-9_]+)\s*\(", tail)
    if not match:
        return None
    kind = match.group(1)
    name = match.group(2)
    i = match.end()
    depth = 1
    params_chars: list[str] = []

    while i < len(tail) and depth > 0:
        ch = tail[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                break
        if depth > 0:
            params_chars.append(ch)
        i += 1

    param_specs = split_top_level("".join(params_chars))
    params = [spec.split("=", 1)[0].strip() for spec in param_specs if spec.strip()]
    return kind, name, params


def parse_param_items_from_text(params_text: str) -> list[tuple[str, str]]:
    items: list[tuple[str, str]] = []
    for item in split_top_level(params_text):
        match = re.match(r"^(.+?)\s*\((.*)\)$", item)
        if match:
            name = match.group(1).strip()
            desc = match.group(2).strip()
        else:
            name = item.strip()
            desc = ""
        split_names = [part.strip() for part in re.split(r"\s*/\s*", name) if part.strip()]
        for split_name in split_names:
            items.append((split_name, desc))
    return items


def clean_bullet_prefix(text: str) -> str:
    stripped = text.strip()
    return re.sub(r"^[-*]\s*", "", stripped)


def parse_param_items(params_lines: list[str]) -> list[tuple[str, str]]:
    compacted = compact_lines(params_lines)
    if not compacted:
        return []

    bulletish = any(line.lstrip().startswith(("-", "*", "`")) for line in compacted)
    if not bulletish and len(compacted) == 1:
        return parse_param_items_from_text(compacted[0])

    items: list[tuple[str, str]] = []
    for line in compacted:
        item = clean_bullet_prefix(line)
        match = re.match(r"^`?([A-Za-z0-9_/$]+(?:\s*/\s*[A-Za-z0-9_/$]+)*)`?\s*:\s*(.*)$", item)
        if match:
            names = [part.strip() for part in re.split(r"\s*/\s*", match.group(1)) if part.strip()]
            desc = match.group(2).strip()
            for name in names:
                items.append((name, desc))
            continue

        legacy = parse_param_items_from_text(item)
        if legacy:
            items.extend(legacy)
        else:
            items.append((item, ""))
    return items


def compact_lines(lines: list[str]) -> list[str]:
    compacted: list[str] = []
    pending_blank = False
    for line in lines:
        stripped = line.strip()
        if not stripped:
            pending_blank = len(compacted) > 0
            continue
        if pending_blank:
            compacted.append("")
            pending_blank = False
        compacted.append(stripped)
    return compacted


def join_for_sentence(lines: list[str]) -> str:
    return " ".join(line for line in compact_lines(lines) if line)


def format_plain_comment(block_text: str, indent: str) -> str:
    lines = extract_block_lines(block_text)
    rendered: list[str] = []
    for line in lines:
        if line:
            rendered.append(f"{indent}// {line}")
        else:
            rendered.append(f"{indent}//")
    return "\n".join(rendered)


def format_docsgen_text_block(label: str, lines: list[str], prefix: str = "//   ") -> list[str]:
    compacted = [clean_bullet_prefix(line) for line in compact_lines(lines)]
    if not compacted:
        return []

    rendered = [f"//   - {label}: {compacted[0]}"]
    for line in compacted[1:]:
        if line:
            rendered.append(f"{prefix}  {line}")
        else:
            rendered.append("//   .")
    return rendered


def render_docsgen_block(fields: dict[str, list[str]], decl: tuple[str, str, list[str]] | None) -> str:
    decl_kind, decl_name, decl_params = decl if decl else ("", "", [])
    if not decl_kind:
        return ""

    kind = "Module" if decl_kind == "module" else "Function"
    explicit_kind = "Module" if "Module" in fields else ("Function" if "Function" in fields else None)
    if explicit_kind and explicit_kind != kind:
        return ""

    summary = join_for_sentence(fields.get(explicit_kind or "Preamble", []))
    if not summary:
        summary = f"{decl_name}."

    lines: list[str] = [f"// {kind}: {decl_name}()"]
    lines.append("// Usage:")
    usage = f"{decl_name}({', '.join(decl_params)});"
    if kind == "Function":
        usage = f"result = {usage}"
    lines.append(f"//   {usage}")

    lines.append("// Description:")
    lines.append(f"//   {summary}")

    extra_description_keys = [
        "Description",
        "Returns",
        "Limitations/Gotchas",
        "Notes",
        "Usage",
        "Examples",
        "Approach",
        "Purpose",
    ]
    for key in extra_description_keys:
        if key not in fields:
            continue
        lines.append("//   .")
        lines.extend(format_docsgen_text_block(key, fields[key]))

    param_items = parse_param_items(fields.get("Params", []))
    if param_items:
        lines.append("// Arguments:")
        for name, desc in param_items:
            lines.append(f"//   {name} = {desc}".rstrip())

    return "\n".join(lines)


def rewrite_source(path: Path) -> bool:
    source_text = path.read_text(encoding="utf-8")
    changed = False
    pieces: list[str] = []
    last = 0

    for match in re.finditer(r"/\*\*(.*?)\*/", source_text, flags=re.DOTALL):
        block_text = match.group(0)
        fields = parse_block(block_text)
        decl = extract_declaration(source_text, match.end())
        line_start = source_text.rfind("\n", 0, match.start()) + 1
        indent = re.match(r"[ \t]*", source_text[line_start:match.start()]).group(0)
        pieces.append(source_text[last:match.start()])
        rendered = render_docsgen_block(fields, decl) if decl else ""
        if rendered:
            pieces.append("\n".join(f"{indent}{line}" if line else indent for line in rendered.splitlines()))
            changed = True
        else:
            pieces.append(format_plain_comment(block_text, indent))
            changed = True
        last = match.end()

    pieces.append(source_text[last:])
    if changed:
        path.write_text("".join(pieces), encoding="utf-8")
    return changed


def expand_paths(raw_paths: Iterable[str]) -> list[Path]:
    paths: list[Path] = []
    seen: set[Path] = set()
    for raw_path in raw_paths:
        path = Path(raw_path).resolve()
        candidates = sorted(path.rglob("*.scad")) if path.is_dir() else [path]
        for candidate in candidates:
            if candidate in seen:
                continue
            seen.add(candidate)
            paths.append(candidate)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+")
    args = parser.parse_args()

    for path in expand_paths(args.paths):
        if rewrite_source(path):
            print(path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
