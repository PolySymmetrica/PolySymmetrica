#!/usr/bin/env python3
"""
Rewrite structured public API Javadoc blocks into docsgen-native line comments.

This intentionally handles only already-structured blocks such as:
  /**
   * Function: ...
   * Params: ...
   * Returns: ...
   */

It leaves freeform prose blocks untouched.
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


def parse_structured_block(block_text: str) -> dict[str, list[str]] | None:
    fields: dict[str, list[str]] = {}
    current_key: str | None = None
    for line in extract_block_lines(block_text):
        if not line:
            if current_key:
                fields.setdefault(current_key, []).append("")
            continue
        match = re.match(r"^(Function|Module|Params|Returns|Limitations/Gotchas|Limitations):\s*(.*)$", line)
        if match:
            key = match.group(1)
            if key == "Limitations":
                key = "Limitations/Gotchas"
            current_key = key
            fields.setdefault(key, []).append(match.group(2).strip())
        elif current_key:
            fields.setdefault(current_key, []).append(line)
        else:
            return None
    return fields if ("Function" in fields or "Module" in fields) else None


def extract_declaration(source_text: str, start_index: int) -> tuple[str, str, list[str]] | None:
    tail = source_text[start_index:]
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


def parse_param_items(params_text: str) -> list[tuple[str, str]]:
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


def render_docsgen_block(fields: dict[str, list[str]], decl: tuple[str, str, list[str]] | None) -> str:
    kind = "Module" if "Module" in fields else "Function"
    summary = " ".join(part for part in fields[kind] if part).strip()
    decl_kind, decl_name, decl_params = decl if decl else (kind.lower(), "", [])
    if decl_kind != kind.lower():
        return ""

    lines: list[str] = [f"// {kind}: {decl_name}()"]
    lines.append("// Usage:")
    usage = f"{decl_name}({', '.join(decl_params)});"
    if kind == "Function":
        usage = f"result = {usage}"
    lines.append(f"//   {usage}")

    lines.append("// Description:")
    lines.append(f"//   {summary}")

    returns = " ".join(part for part in fields.get("Returns", []) if part).strip()
    if returns:
        lines.append("//   .")
        lines.append(f"//   - Returns: {returns}")

    for limitation in [part.strip() for part in fields.get('Limitations/Gotchas', []) if part.strip()]:
        lines.append("//   .")
        lines.append(f"//   - Limitations/Gotchas: {limitation}")

    params = " ".join(part for part in fields.get("Params", []) if part).strip()
    param_items = parse_param_items(params) if params else []
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
        fields = parse_structured_block(block_text)
        decl = extract_declaration(source_text, match.end())
        pieces.append(source_text[last:match.start()])
        if fields and decl and not decl[1].startswith("_ps_"):
            rendered = render_docsgen_block(fields, decl)
            if rendered:
                pieces.append(rendered)
                changed = True
            else:
                pieces.append(block_text)
        else:
            pieces.append(block_text)
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
