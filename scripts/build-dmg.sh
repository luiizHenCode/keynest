#!/bin/sh
set -eu
# Usage: sh scripts/build-dmg.sh [Developer-ID-identity] [notarytool-keychain-profile]
IDENTITY="${1:--}"
PROFILE="${2:-}"
ROOT="$(pwd)"
STAGE="$ROOT/build/dmg-staging"
# Finder stores the mount path in .DS_Store background bookmarks. Never use a home path.
MOUNT="/Volumes/Keynest"
RW="$ROOT/build/Keynest-install-rw.dmg"
DMG="$ROOT/build/Keynest-1.0.0-arm64.dmg"
if [ "$IDENTITY" = "-" ] && [ -n "$PROFILE" ]; then
    printf 'Notarização exige uma assinatura Developer ID, não ad-hoc.\n' >&2
    exit 1
fi
sh scripts/build-app.sh "$IDENTITY"
build/Keynest.app/Contents/MacOS/MacTap --check-resources
if mount | grep -F " on $MOUNT " >/dev/null; then
    printf 'O volume de instalação já está montado em %s. Ejete-o antes de repetir.\n' "$MOUNT" >&2
    exit 1
fi
rm -rf "$STAGE"
mkdir -p "$STAGE"
ditto build/Keynest.app "$STAGE/Keynest.app"
ln -s /Applications "$STAGE/Applications"

cp Resources/Keynest.icns "$STAGE/.VolumeIcon.icns"
xcrun SetFile -a C "$STAGE"
hdiutil create -ov -volname Keynest -fs HFS+ -srcfolder "$STAGE" -format UDRW "$RW"
hdiutil attach -nobrowse -mountpoint "$MOUNT" "$RW"
trap 'hdiutil detach "$MOUNT" >/dev/null 2>&1 || true' EXIT INT TERM
if ! osascript scripts/layout-dmg.applescript "$MOUNT"; then
    printf 'Não foi possível personalizar o Finder; o DMG mantém o app e o atalho de instalação.\n' >&2
fi
sync
python3 scripts/audit-release.py "$MOUNT"
hdiutil detach "$MOUNT"
trap - EXIT INT TERM
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" -ov
if [ "$IDENTITY" = "-" ]; then
    codesign --force --sign - "$DMG"
else
    codesign --force --timestamp --sign "$IDENTITY" "$DMG"
fi
codesign --verify --strict "$DMG"
hdiutil verify "$DMG"
if [ -n "$PROFILE" ]; then
    # Credentials stay in Keychain. Do not pass passwords or API private keys here.
    xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait --timeout 5m \
        --output-format json > "$ROOT/build/notarization-result.json"
    python3 - "$ROOT/build/notarization-result.json" <<'PY'
import json
import sys
with open(sys.argv[1]) as result:
    status = json.load(result)
print("Notarization:", status.get("status"), "Submission:", status.get("id"))
if status.get("status") != "Accepted":
    raise SystemExit("Notarization was not accepted; do not publish this build.")
PY
    xcrun stapler staple "$DMG"
    xcrun stapler validate "$DMG"
    spctl --assess --type open --context context:primary-signature --verbose=2 "$DMG"
    xcrun stapler staple "$ROOT/build/Keynest.app"
    xcrun stapler validate "$ROOT/build/Keynest.app"
    spctl --assess --type execute --verbose=2 "$ROOT/build/Keynest.app"
else
    printf '\nATENÇÃO: DMG assinado, mas NÃO notarizado. Para notarizar, passe o nome do perfil notarytool do Chaveiro como segundo argumento.\n'
fi
python3 - "$DMG" <<'PY'
import hashlib
import sys
from pathlib import Path
path = Path(sys.argv[1])
digest = hashlib.sha256(path.read_bytes()).hexdigest()
Path(str(path) + ".sha256").write_text(f"{digest}  {path.name}\n")
PY
rm -f "$RW"
printf '\nInstalador criado: %s\n' "$DMG"
