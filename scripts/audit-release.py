#!/usr/bin/env python3
"""Fail packaging when the mounted payload contains private build paths/account metadata.

Developer ID's public certificate identity is intentionally not classified as a secret.
No file content or matched credential is printed.
"""
from pathlib import Path
import getpass
import re
import sys


def main():
    root = Path(sys.argv[1])
    username = getpass.getuser()
    account_markers = []
    if len(username) >= 4 and username not in {"root", "builder", "runner"}:
        account_markers = [username.encode(encoding) for encoding in ("utf-8", "utf-16le", "utf-16be")]
    path_patterns = [re.compile(rb"/(?:Users|home)/[A-Za-z0-9_.-]+/")]
    path_markers = ["/Users/".encode("utf-16le"), "/Users/".encode("utf-16be")]
    findings = []
    checked = 0
    for path in root.rglob("*"):
        if path.is_symlink() or not path.is_file():
            continue
        checked += 1
        data = path.read_bytes()
        if any(pattern.search(data) for pattern in path_patterns) or any(marker in data for marker in path_markers):
            findings.append((path.relative_to(root), "private home path"))
        if any(marker in data for marker in account_markers):
            findings.append((path.relative_to(root), "local account metadata"))
    for path, reason in findings:
        print(f"Privacy audit failed: {path} ({reason})", file=sys.stderr)
    if findings:
        raise SystemExit("Do not publish or notarize this payload until its metadata is cleaned.")
    print(f"Release privacy audit passed: {checked} payload files checked.")


if __name__ == "__main__":
    main()
