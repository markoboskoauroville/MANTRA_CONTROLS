#!/bin/sh
# build.sh — the Swift controllers, one .app per app, from Sources/Common plus the app's own folder.
#
#     sh build.sh            both
#     sh build.sh midikeys   one
#
# swiftc straight, no Xcode project, the same way STAR_LAUNCHER is built. The bundles go to apps/,
# which is not in git: they are built here, and the star opens them from here.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$HERE/apps"

one() {   # folder, app name, bundle id
    SRC=$1; NAME=$2; BID=$3
    APP="$HERE/apps/$NAME.app"
    rm -rf "$APP"
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
    swiftc -O -parse-as-library -swift-version 5 \
        -target arm64-apple-macosx14.0 \
        -o "$APP/Contents/MacOS/$NAME" \
        "$HERE"/Sources/Common/*.swift "$HERE"/Sources/$SRC/*.swift
    VER=$(grep -m1 'let VERSION' "$HERE"/Sources/$SRC/*.swift | sed 's/.*"v\([0-9]*\)".*/\1/')
    cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$NAME</string>
  <key>CFBundleDisplayName</key><string>$NAME</string>
  <key>CFBundleExecutable</key><string>$NAME</string>
  <key>CFBundleIdentifier</key><string>$BID</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VER</string>
  <key>CFBundleVersion</key><string>$VER</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSAppTransportSecurity</key><dict><key>NSAllowsLocalNetworking</key><true/></dict>
</dict>
</plist>
PLIST
    codesign --force -s - "$APP" >/dev/null 2>&1 || true
    echo "built: $APP (v$VER)"
}

[ -z "$1" -o "$1" = midikeys ] && one MidiKeys "MIDI to Key Stroke" com.mantra.controls.midikeys
[ -z "$1" -o "$1" = mackie ]   && one Mackie   "MIDI to MK Control" com.mantra.controls.mackie
exit 0
