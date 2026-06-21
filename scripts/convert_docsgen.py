#!/usr/bin/env python3
"""
Build docsgen-friendly scratch copies of PolySymmetrica source files.

This keeps the real source comments untouched and emits converted files into a
scratch tree for iteration with `openscad-docsgen`.
"""

from __future__ import annotations

import argparse
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT_ROOT = REPO_ROOT / ".tmp" / "docsgen-src"
DEFAULT_DOCS_OUT = REPO_ROOT / ".tmp" / "docsgen-out"


@dataclass
class DocBlock:
    kind: str
    summary: str
    params: str | None
    returns: str | None
    limitations: list[str]


@dataclass
class Declaration:
    kind: str
    name: str
    params: list[str]


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


def parse_doc_block(block_text: str) -> DocBlock | None:
    raw_lines = block_text.splitlines()
    lines: list[str] = []
    for line in raw_lines:
        stripped = line.strip()
        if stripped.startswith("/**") or stripped == "*/":
            continue
        if stripped.startswith("*"):
            stripped = stripped[1:].lstrip()
        lines.append(stripped)

    fields: dict[str, list[str]] = {}
    current_key: str | None = None
    for line in lines:
        if not line:
            if current_key:
                fields.setdefault(current_key, []).append("")
            continue
        match = re.match(r"^(Function|Module|Params|Returns|Limitations/Gotchas|Limitations):\s*(.*)$", line)
        if match:
            current_key = match.group(1)
            if current_key == "Limitations":
                current_key = "Limitations/Gotchas"
            fields.setdefault(current_key, []).append(match.group(2).strip())
        elif current_key:
            fields.setdefault(current_key, []).append(line)

    doc_kind = None
    summary = None
    for key in ("Function", "Module"):
        if key in fields:
            doc_kind = key.lower()
            summary = " ".join(part for part in fields[key] if part).strip()
            break

    if not doc_kind or not summary:
        return None

    params = None
    if "Params" in fields:
        params = " ".join(part for part in fields["Params"] if part).strip()

    returns = None
    if "Returns" in fields:
        returns = " ".join(part for part in fields["Returns"] if part).strip()

    limitations = []
    if "Limitations/Gotchas" in fields:
        limitations = [part.strip() for part in fields["Limitations/Gotchas"] if part.strip()]

    return DocBlock(
        kind=doc_kind,
        summary=summary,
        params=params,
        returns=returns,
        limitations=limitations,
    )


def extract_declaration(source_text: str, start_index: int) -> Declaration | None:
    tail = source_text[start_index:]
    match = re.match(r"\s*(function|module)\s+([A-Za-z0-9_]+)\s*\(", tail)
    if not match:
        return None

    decl_kind = match.group(1)
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
                i += 1
                break
        if depth > 0:
            params_chars.append(ch)
        i += 1

    param_specs = split_top_level("".join(params_chars))
    param_names = [spec.split("=", 1)[0].strip() for spec in param_specs if spec.strip()]
    return Declaration(kind=decl_kind, name=name, params=param_names)


def parse_param_items(params_text: str | None) -> list[tuple[str, str]]:
    if not params_text:
        return []

    items: list[tuple[str, str]] = []
    for item in split_top_level(params_text):
        match = re.match(r"^(.+?)\s*\((.*)\)$", item)
        if match:
            name = match.group(1).strip()
            desc = match.group(2).strip()
        else:
            name = item.strip()
            desc = ""
        if name:
            split_names = [part.strip() for part in re.split(r"\s*/\s*", name) if part.strip()]
            if split_names:
                for split_name in split_names:
                    items.append((split_name, desc))
            else:
                items.append((name, desc))
    return items


def make_usage(decl: Declaration) -> list[str]:
    args = ", ".join(decl.params)
    call = f"{decl.name}({args});"
    if decl.kind == "function":
        call = f"result = {call}"
    return [call]


def render_docsgen_block(doc: DocBlock, decl: Declaration) -> str:
    lines: list[str] = []
    header_kind = "Function" if decl.kind == "function" else "Module"
    lines.append(f"// {header_kind}: {decl.name}()")
    lines.append("// Usage:")
    for usage_line in make_usage(decl):
        lines.append(f"//   {usage_line}")

    lines.append("// Description:")
    lines.append(f"//   {doc.summary}")
    if doc.returns:
        lines.append("//   .")
        lines.append(f"//   - Returns: {doc.returns}")
    for limitation in doc.limitations:
        lines.append("//   .")
        lines.append(f"//   - Limitations/Gotchas: {limitation}")

    param_items = parse_param_items(doc.params)
    if param_items:
        lines.append("// Arguments:")
        for name, desc in param_items:
            lines.append(f"//   {name} = {desc}".rstrip())

    return "\n".join(lines)


def should_keep_block(doc: DocBlock, decl: Declaration | None, visibility: str) -> bool:
    if decl is None:
        return False
    if doc.kind != decl.kind:
        return False
    if visibility == "all":
        return True
    return not decl.name.startswith("_")


def infer_import_path(rel_path: Path) -> str:
    parts = rel_path.parts
    if len(parts) >= 2 and parts[0] == "src":
        return "/".join(parts[1:])
    return rel_path.as_posix()


def build_file_header(rel_path: Path, visibility: str) -> str:
    basename = rel_path.name
    import_path = infer_import_path(rel_path)
    section_title = "Public API" if visibility == "public" else "Documented API"
    return "\n".join(
        [
            f"// LibFile: {basename}",
            f"//   Scratch docsgen conversion for `{import_path}`.",
            "// FileSummary: Generated docsgen preview converted from in-source Javadoc comments.",
            "// Includes:",
            f"//   use <{import_path}>",
            f"// Section: {section_title}",
            "//   Generated automatically by scripts/convert_docsgen.py.",
            "",
        ]
    )


def convert_source(source_path: Path, rel_path: Path, output_root: Path, visibility: str) -> Path:
    source_text = source_path.read_text(encoding="utf-8")
    out_parts = list(rel_path.parts)
    if out_parts and out_parts[0] == "src":
        out_parts = out_parts[1:]
    output_path = output_root.joinpath(*out_parts)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    pieces: list[str] = [build_file_header(rel_path, visibility)]
    last_index = 0

    for match in re.finditer(r"/\*\*(.*?)\*/", source_text, flags=re.DOTALL):
        block_text = match.group(0)
        doc = parse_doc_block(block_text)
        decl = extract_declaration(source_text, match.end())

        pieces.append(source_text[last_index:match.start()])
        if doc and should_keep_block(doc, decl, visibility):
            pieces.append(render_docsgen_block(doc, decl))
        else:
            pieces.append(block_text)
        last_index = match.end()

    pieces.append(source_text[last_index:])
    output_path.write_text("".join(pieces), encoding="utf-8")
    return output_path


def run_docsgen(docsgen_bin: str, docs_out: Path, converted_paths: Iterable[Path]) -> None:
    cmd = [
        docsgen_bin,
        "-D",
        str(docs_out),
        "-n",
        "-m",
        *[str(path) for path in converted_paths],
    ]
    subprocess.run(cmd, check=True)


def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "paths",
        nargs="+",
        help="Source .scad files to convert.",
    )
    parser.add_argument(
        "--visibility",
        choices=("public", "all"),
        default="public",
        help="Emit docsgen blocks for public declarations only, or for all documented declarations.",
    )
    parser.add_argument(
        "--output-root",
        type=Path,
        default=DEFAULT_OUTPUT_ROOT,
        help=f"Scratch output root. Default: {DEFAULT_OUTPUT_ROOT}",
    )
    parser.add_argument(
        "--run-docsgen",
        action="store_true",
        help="Run openscad-docsgen on the converted scratch files after conversion.",
    )
    parser.add_argument(
        "--docsgen-bin",
        default="openscad-docsgen",
        help="Docsgen executable to run with --run-docsgen.",
    )
    parser.add_argument(
        "--docs-out",
        type=Path,
        default=DEFAULT_DOCS_OUT,
        help=f"Docsgen output directory when using --run-docsgen. Default: {DEFAULT_DOCS_OUT}",
    )
    return parser


def main() -> int:
    parser = build_arg_parser()
    args = parser.parse_args()

    converted_paths: list[Path] = []
    for raw_path in args.paths:
        source_path = Path(raw_path).resolve()
        rel_path = source_path.relative_to(REPO_ROOT)
        converted_paths.append(
            convert_source(
                source_path=source_path,
                rel_path=rel_path,
                output_root=args.output_root.resolve(),
                visibility=args.visibility,
            )
        )

    for path in converted_paths:
        print(path)

    if args.run_docsgen:
        args.docs_out.mkdir(parents=True, exist_ok=True)
        run_docsgen(args.docsgen_bin, args.docs_out.resolve(), converted_paths)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
