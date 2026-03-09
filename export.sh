#!/bin/bash
# Export VSGames as standalone macOS app
set -e

SKETCH_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SKETCH_DIR/build"
APP="$BUILD_DIR/VSGames.app"
PROCESSING="/Applications/Processing.app/Contents/MacOS/Processing"
JDK="/Applications/Processing.app/Contents/app/resources/jdk"
TMP_DIR="$SKETCH_DIR/build-tmp"

echo "Exporting VSGames..."

# Export sketch to get compiled jars
rm -rf "$TMP_DIR"
"$PROCESSING" cli --sketch="$SKETCH_DIR" --output="$TMP_DIR" --force --no-java --export

# Create clean app bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Java"
mkdir -p "$APP/Contents/Resources"

# Copy jars
cp "$TMP_DIR/VSGames.app/Contents/Java/"* "$APP/Contents/Java/"

# Shell script launcher
cat > "$APP/Contents/MacOS/VSGames" << 'LAUNCHER'
#!/bin/bash
DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
xattr -cr "$APP_DIR" 2>/dev/null
JAVA="$DIR/runtime/bin/java"
exec "$JAVA" \
  -Djava.awt.headless=false \
  -Djava.library.path="$DIR/Java:$DIR/Java/core/library" \
  -cp "$DIR/Java/*" \
  VSGames "$@"
LAUNCHER
chmod +x "$APP/Contents/MacOS/VSGames"

# Info.plist
cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>VSGames</string>
  <key>CFBundleIdentifier</key>
  <string>com.vsgames.app</string>
  <key>CFBundleName</key>
  <string>VSGames</string>
  <key>CFBundleDisplayName</key>
  <string>VS Games</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>LSMultipleInstancesProhibited</key>
  <false/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

# Embed JDK runtime
cp -R "$JDK" "$APP/Contents/runtime"

# Clear quarantine
xattr -cr "$APP"

# Create DMG for distribution
DMG="$BUILD_DIR/VSGames.dmg"
rm -f "$DMG"
hdiutil create -volname "VS Games" -srcfolder "$APP" -ov -format UDZO "$DMG" > /dev/null
echo "Created DMG: $DMG"

# Cleanup
rm -rf "$TMP_DIR"

echo "Done! App at: $APP"
echo "Open with:            open \"$APP\""
echo "Second instance with: open -n \"$APP\""
echo "Share with:           $DMG"
