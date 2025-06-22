#!/usr/bin/env bash
set -euo pipefail

BASE_ICON="AppIcon-1024.png"
if [[ ! -f "$BASE_ICON" ]]; then
  echo "Error: base icon not found: $BASE_ICON"
  echo "Place your 1024×1024 PNG at the project root as $BASE_ICON"
  exit 1
fi

ICONSET_DIR="$(mktemp -d /tmp/iconset.XXXXXX)"

declare -a sizes=(16 32 128 256 512)
declare -a scales=(1 2)

for size in "${sizes[@]}"; do
  for scale in "${scales[@]}"; do
    pixel_size=$((size * scale))
    output="${ICONSET_DIR}/icon_${size}x${size}@${scale}x.png"
    sips -z "$pixel_size" "$pixel_size" "$BASE_ICON" --out "$output" >/dev/null
  done
done

ASSET_DIR="ttcd/Assets.xcassets/AppIcon.appiconset"

# Copy individual PNG files to the asset directory
cp "${ICONSET_DIR}"/icon_*.png "${ASSET_DIR}/"

# Also generate an ICNS file
ICNS_OUTPUT="${ASSET_DIR}/Icon.icns"
iconutil -c icns "$ICONSET_DIR" --output "$ICNS_OUTPUT"

rm -rf "$ICONSET_DIR"

echo "✅ Generated app icon files in $ASSET_DIR"
echo "✅ Generated $ICNS_OUTPUT"