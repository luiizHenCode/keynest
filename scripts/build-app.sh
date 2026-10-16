#!/bin/sh
set -eu
# Run from the repository root. Local builds default to ad-hoc signing.
# Pass your own Developer ID Application identity explicitly for distribution.
IDENTITY="${1:--}"
APP="${2:-build/Keynest.app}"
# Omit debug information; the executable is stripped before signing as a second safeguard.
swift build -c release -Xswiftc -gnone
if [ ! -f Resources/Keynest.icns ]; then
    swift scripts/generate-brand.swift
    iconutil -c icns Resources/Keynest.iconset -o Resources/Keynest.icns
fi
python3 scripts/sanitize-brand.py
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
rm -rf "$APP/Contents/Resources/MacTap_MacTap.bundle"
cp -R .build/release/MacTap_MacTap.bundle "$APP/Contents/Resources/MacTap_MacTap.bundle"
for notice in THIRD_PARTY_NOTICES.md AMBIENCE_NOTICES.md NATURE_NOTICES.md LOFI_NOTICES.md; do
    cp "$notice" "$APP/Contents/Resources/$notice"
done
cp .build/release/MacTap "$APP/Contents/MacOS/MacTap"
strip -S "$APP/Contents/MacOS/MacTap"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/Keynest.icns "$APP/Contents/Resources/Keynest.icns"
for locale in en pt-BR; do
    mkdir -p "$APP/Contents/Resources/$locale.lproj"
    cp "Resources/Localization/$locale.lproj/InfoPlist.strings" "$APP/Contents/Resources/$locale.lproj/InfoPlist.strings"
done
if [ "$IDENTITY" = "-" ]; then
    codesign --force --sign - --identifier com.l4apps.mactap "$APP"
else
    codesign --force --options runtime --timestamp --sign "$IDENTITY" --identifier com.l4apps.mactap "$APP"
fi
codesign --verify --deep --strict "$APP"
printf '\nAplicativo criado em %s\nAbra com: open "%s"\n' "$APP" "$APP"
