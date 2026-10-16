#!/usr/bin/env python3
"""Remove metadata from generated Keynest artwork without re-encoding pixels."""
from pathlib import Path
import struct

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
PRIVATE_CHUNKS = {b"eXIf", b"tEXt", b"zTXt", b"iTXt"}


def clean_png(data):
    if not data.startswith(PNG_SIGNATURE):
        return data
    output = bytearray(PNG_SIGNATURE)
    offset = 8
    while offset < len(data):
        if offset + 12 > len(data):
            raise ValueError("Invalid PNG chunk")
        length = struct.unpack_from(">I", data, offset)[0]
        end = offset + 12 + length
        if end > len(data):
            raise ValueError("Truncated PNG chunk")
        if data[offset + 4:offset + 8] not in PRIVATE_CHUNKS:
            output.extend(data[offset:end])
        offset = end
    return bytes(output)


def clean_icns(data):
    if data[:4] != b"icns":
        raise ValueError("Invalid icon container")
    output = bytearray()
    offset = 8
    while offset < len(data):
        kind = data[offset:offset + 4]
        length = struct.unpack_from(">I", data, offset + 4)[0]
        if length < 8 or offset + length > len(data):
            raise ValueError("Invalid icon element")
        payload = clean_png(data[offset + 8:offset + length])
        output.extend(kind + struct.pack(">I", len(payload) + 8) + payload)
        offset += length
    return b"icns" + struct.pack(">I", len(output) + 8) + output


def main():
    resources = Path(__file__).resolve().parent.parent / "Resources"
    files = list(resources.glob("Keynest*.png")) + list(resources.glob("Keynest.iconset/*.png"))
    files += [resources / "dmg-background.png", resources / "Keynest.icns"]
    changed = 0
    for path in files:
        if not path.exists():
            continue
        original = path.read_bytes()
        cleaned = clean_icns(original) if path.suffix == ".icns" else clean_png(original)
        if cleaned != original:
            path.write_bytes(cleaned)
            changed += 1
    print(f"Brand metadata audit: {len(files)} files checked, {changed} sanitized.")


if __name__ == "__main__":
    main()
