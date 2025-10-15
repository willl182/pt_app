"""Lightweight stub implementation of the Rscript command.

This module provides a minimal subset of Rscript behaviour that is good
enough for automated syntax checks within the execution environment that
lacks a native R installation.  The primary goal is to allow commands of
The form ``Rscript -e "source('file.R')"`` to succeed while performing a
basic structural validation of the referenced R file.

It is *not* a replacement for a real R interpreter; it merely checks for
obvious syntax issues such as unbalanced brackets or unterminated string
literals.  The script exits with a non-zero status code and surfaces a
human readable error message whenever such issues are detected.
"""
from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional


class RscriptStubError(Exception):
    """Custom exception for stub execution errors."""


@dataclass
class SourceResult:
    """Stores the result of validating a sourced file."""

    path: Path
    statements_checked: int


SOURCE_PATTERN = re.compile(r"^source\((['\"])(?P<path>.+?)\1\)$")


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    """Parse command line arguments accepted by the stub."""
    parser = argparse.ArgumentParser(
        description=(
            "Minimal Rscript replacement that supports `-e` expressions to "
            "source R files and run structural validation checks."
        ),
        add_help=False,
    )

    parser.add_argument("-e", "--expression", dest="expressions", action="append")
    parser.add_argument("--help", action="store_true", dest="help_requested")
    parser.add_argument("--version", action="store_true", dest="show_version")
    parser.add_argument("script", nargs="?")
    parser.add_argument("args", nargs=argparse.REMAINDER)

    args = parser.parse_args(list(argv) if argv is not None else None)

    if args.help_requested:
        parser.print_help()
        raise SystemExit(0)

    if args.show_version:
        print("Rscript stub 0.1")
        raise SystemExit(0)

    if args.script and args.expressions:
        raise RscriptStubError(
            "Providing both a script path and -e expressions is not supported "
            "by the stub."
        )

    if not args.script and not args.expressions:
        raise RscriptStubError(
            "No expression or script provided. Use -e "
            "\"source('file.R')\" to validate an R file."
        )

    return args


def main(argv: Optional[Iterable[str]] = None) -> None:
    """Entry point for the stub Rscript implementation."""
    try:
        args = parse_args(argv)

        if args.script:
            raise RscriptStubError(
                "Executing standalone R scripts is not supported in the stub. "
                "Use -e \"source('file.R')\" instead."
            )

        results: List[SourceResult] = []
        for expr in args.expressions or []:
            results.append(evaluate_expression(expr))

        if results:
            for result in results:
                print(
                    f"[rscript-stub] Validated {result.statements_checked} structural "
                    f"elements in {result.path}"
                )
    except RscriptStubError as exc:
        print(f"Rscript stub error: {exc}", file=sys.stderr)
        raise SystemExit(2) from exc


def evaluate_expression(expression: str) -> SourceResult:
    """Validate the expression supported by the stub."""
    expression = expression.strip()
    match = SOURCE_PATTERN.match(expression)
    if not match:
        raise RscriptStubError(
            "Unsupported expression. The stub currently only recognises "
            "source('path/to/file.R')."
        )

    rel_path = match.group("path")
    file_path = Path(rel_path).expanduser().resolve()
    if not file_path.exists():
        raise RscriptStubError(f"The file {rel_path!r} does not exist.")

    content = file_path.read_text(encoding="utf-8")
    statements_checked = structural_validate(content, file_path)
    return SourceResult(path=file_path, statements_checked=statements_checked)


BRACKET_PAIRS = {"(": ")", "[": "]", "{": "}"}
CLOSERS = {value: key for key, value in BRACKET_PAIRS.items()}


def structural_validate(content: str, file_path: Path) -> int:
    """Perform lightweight structural checks on the R source."""
    stack: List[tuple[str, int, int]] = []
    statements_checked = 0

    in_string: Optional[str] = None
    escape = False
    line = 1
    column = 0

    i = 0
    while i < len(content):
        char = content[i]

        if char == "\n":
            line += 1
            column = 0
        else:
            column += 1

        if in_string is not None:
            if escape:
                escape = False
            elif char == "\\":
                escape = True
            elif char == in_string:
                in_string = None
            i += 1
            continue

        if char in ('"', "'"):
            in_string = char
            i += 1
            continue

        if char == "#":
            # Skip comment until the end of the line.
            newline_pos = content.find("\n", i + 1)
            if newline_pos == -1:
                break
            i = newline_pos
            continue

        if char in BRACKET_PAIRS:
            stack.append((char, line, column))
            statements_checked += 1
        elif char in CLOSERS:
            if not stack:
                raise RscriptStubError(
                    _format_error(
                        file_path,
                        line,
                        column,
                        f"Unmatched closing bracket '{char}'.",
                    )
                )
            opener, opener_line, opener_column = stack.pop()
            expected = BRACKET_PAIRS[opener]
            if expected != char:
                raise RscriptStubError(
                    _format_error(
                        file_path,
                        line,
                        column,
                        f"Expected '{expected}' to close '{opener}' opened at "
                        f"line {opener_line}, column {opener_column}.",
                    )
                )
            statements_checked += 1

        i += 1

    if in_string is not None:
        raise RscriptStubError(
            _format_error(
                file_path,
                line,
                column,
                f"Unterminated string literal delimited by {in_string!r}.",
            )
        )

    if stack:
        opener, opener_line, opener_column = stack[-1]
        expected = BRACKET_PAIRS[opener]
        raise RscriptStubError(
            _format_error(
                file_path,
                opener_line,
                opener_column,
                f"Unclosed bracket '{opener}' (expected '{expected}').",
            )
        )

    return statements_checked


def _format_error(path: Path, line: int, column: int, message: str) -> str:
    return f"{path}:{line}:{column}: {message}"


if __name__ == "__main__":  # pragma: no cover - script entry point
    main()
