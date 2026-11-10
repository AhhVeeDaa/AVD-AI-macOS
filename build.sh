#!/bin/bash
set -e

echo "=== WITNESS v1.0 BUILT WITH XCODE ==="
echo ""

# Accept Xcode licenses if needed
if [ ! -f ~/.xcode/accepted ]; then
    echo "Accepting Xcode licenses..."
    sudo xcodebuild -license > /dev/null 2>&1
    touch ~/.xcode/accepted
else
    echo "Xcode licenses already accepted"
fi

# Build release
echo ""
echo "Building with swiftc/swift..."
swift build -c release

# Copy to app bundle location
if [ -d build/release/witnessapp ]; then
    rm -rf Witness-v1.0.0.app
    cp -a build/release/witnessapp Witness-v1.0.0.app
    echo ""
    echo "App created: Witness-v1.0.0.app"
fi

# Create DMG
echo ""
echo "Creating DMG..."
hdiutil createburner \
    --src . \
    --dest Witness-v1.0.0.dmg \
    --volname "Witness v1.0.0" \
    --ov format UDZO \
    --ov fs HFS+ \
    --ov fsargs -f -c 128K-48B \
    --ov lang en-us \
    --ov encrypt no \
    --ov volname Witness-v1.0.0 \
    --ov format UDZO \
    --ov volume-label "Witness v1.0.0"

# Create ZIP
echo ""
echo "Creating ZIP..."
zip -r -X Witness.v1.0.0.zip .

# Generate checksums
echo ""
echo "Generating SHA256 checksums..."
cd /Users/ahhveedaa/.openclaw/workspace
sha256sum Witness-v1.0.0.dmg Witness.v1.0.0.zip > SHA256SUMS.txt

echo ""
echo "=== BUILD COMPLETE ==="
ls -lh Witness-v1.0.0.dmg Witness.v1.0.0.zip Witness-v1.0.0.app 2>/dev/null || echo "Some files may not be ready yet"
