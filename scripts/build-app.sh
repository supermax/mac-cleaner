#!/bin/zsh
set -euo pipefail

project_dir=${0:A:h:h}
build_dir="$project_dir/.build/release"
app_dir="$project_dir/dist/DevSpace.app"
iconset_dir="$project_dir/dist/DevSpaceIcon.iconset"

rm -rf "$app_dir" "$iconset_dir"
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources" "$iconset_dir"

swift build -c release --package-path "$project_dir"

for size in 16 32 128 256 512; do
  sips -s format png -z "$size" "$size" "$project_dir/Resources/DevSpaceIcon.svg" --out "$iconset_dir/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -s format png -z "$double" "$double" "$project_dir/Resources/DevSpaceIcon.svg" --out "$iconset_dir/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset_dir" -o "$app_dir/Contents/Resources/DevSpaceIcon.icns"
cp "$project_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$build_dir/DevSpace" "$app_dir/Contents/MacOS/DevSpace"
chmod +x "$app_dir/Contents/MacOS/DevSpace"

echo "Built $app_dir"
