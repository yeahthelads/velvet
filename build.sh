#!/bin/zsh
set -eu
cd "$(dirname "$0")"
APP="$PWD/build/Velvet.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$PWD/build/module-cache"
swiftc -swift-version 5 -O -module-cache-path "$PWD/build/module-cache" \
  Sources/CoffeeState.swift Sources/CompanionCare.swift Sources/FocusSession.swift Sources/CompanionInteraction.swift Sources/CompanionResponse.swift Sources/PerformanceState.swift Sources/StimulationState.swift Sources/Store.swift Sources/SpriteAtlas.swift Sources/CompanionAudio.swift Sources/Character.swift Sources/NotesView.swift Sources/App.swift \
  -o "$APP/Contents/MacOS/Velvet" -framework AppKit -framework SwiftUI -framework Carbon
cp Info.plist "$APP/Contents/Info.plist"
if [[ -f Assets/Velvet.icns ]]; then cp Assets/Velvet.icns "$APP/Contents/Resources/Velvet.icns"; fi
cp Assets/velvet-sprites-v5.png "$APP/Contents/Resources/velvet-sprites-v5.png"
cp Assets/vogue-sprites-v2.png "$APP/Contents/Resources/vogue-sprites-v2.png"
cp Assets/iced-latte-sprites-v2.png "$APP/Contents/Resources/iced-latte-sprites-v2.png"
cp Assets/interaction-sprites-v2.png "$APP/Contents/Resources/interaction-sprites-v2.png"
cp Assets/wellbeing-sprites-v1.png "$APP/Contents/Resources/wellbeing-sprites-v1.png"
cp Assets/disco-sprites-v1.png "$APP/Contents/Resources/disco-sprites-v1.png"
cp Assets/club-sprites-v1.png "$APP/Contents/Resources/club-sprites-v1.png"
cp Assets/stretch-sprites-v1.png "$APP/Contents/Resources/stretch-sprites-v1.png"
cp Assets/breakdance-sprites-v1.png "$APP/Contents/Resources/breakdance-sprites-v1.png"
# Optional local audio: remove old bundled copies before selecting current files.
for sample in vogue-chant head-pet tumble coffee crossed-arms breakdance overwhelmed-sleep clap house waacking latte-riser latte-liquor latte-sip vogue-sound; do
  for extension in wav mp3 m4a aiff aif; do
    rm -f "$APP/Contents/Resources/$sample.$extension"
    if [[ -f "Assets/$sample.$extension" ]]; then
      cp "Assets/$sample.$extension" "$APP/Contents/Resources/$sample.$extension"
    fi
  done
done
codesign --force --sign - "$APP"
echo "Built $APP"
