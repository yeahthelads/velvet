#!/bin/zsh
set -eu
cd "$(dirname "$0")"
APP="$PWD/build/Velvet.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$PWD/build/module-cache"
swiftc -swift-version 5 -O -module-cache-path "$PWD/build/module-cache" \
  Sources/JerseyReaction.swift Sources/StylingState.swift Sources/BodyStyling.swift Sources/StylingMenu.swift Sources/StylingChecks.swift Sources/DrawingGiftState.swift Sources/DrawingGift.swift Sources/DrawingGiftChecks.swift Sources/IronState.swift Sources/IronAccessory.swift Sources/IronChecks.swift Sources/LifestyleState.swift Sources/CoffeeState.swift Sources/CompanionCare.swift Sources/FocusSession.swift Sources/CompanionInteraction.swift Sources/CompanionResponse.swift Sources/PerformanceState.swift Sources/ListeningState.swift Sources/SystemAudioMonitor.swift Sources/StimulationState.swift Sources/Store.swift Sources/SpriteAtlas.swift Sources/CompanionAudio.swift Sources/Character.swift Sources/NotesView.swift Sources/App.swift \
  Sources/CompanionRoutine.swift Sources/CompanionRest.swift Sources/CareMechanicsChecks.swift Sources/RoutineChecks.swift Sources/PerformanceChecks.swift Sources/SongRequestState.swift Sources/SongRequest.swift Sources/SongRequestChecks.swift Sources/TutorialState.swift Sources/TutorialView.swift Sources/LifestyleChecks.swift \
  -o "$APP/Contents/MacOS/Velvet" -framework AppKit -framework SwiftUI -framework Carbon -framework CoreAudio
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
cp Assets/care-sprites-v2.png "$APP/Contents/Resources/care-sprites-v2.png"
cp Assets/daily-sprites-v1.png "$APP/Contents/Resources/daily-sprites-v1.png"
cp Assets/yoga-sprites-v2.png "$APP/Contents/Resources/yoga-sprites-v2.png"
cp Assets/styling-sprites-v1.png "$APP/Contents/Resources/styling-sprites-v1.png"
cp Assets/drawing-robots-kiss-v1.png "$APP/Contents/Resources/drawing-robots-kiss-v1.png"
cp Assets/drawing-sprites-v1.png "$APP/Contents/Resources/drawing-sprites-v1.png"
# Optional local audio: remove old bundled copies before selecting current files.
for sample in jersey-laugh jersey-shy jersey-attitude jersey-pleased vogue-chant head-pet tumble coffee crossed-arms breakdance overwhelmed-sleep clap house waacking ballet disco floorwork contemporary latte-riser latte-liquor latte-sip vogue-sound; do
  for extension in wav mp3 m4a aiff aif; do
    rm -f "$APP/Contents/Resources/$sample.$extension"
    if [[ -f "Assets/$sample.$extension" ]]; then
      cp "Assets/$sample.$extension" "$APP/Contents/Resources/$sample.$extension"
    fi
  done
done
cp Assets/MUSIC-CREDITS.txt "$APP/Contents/Resources/MUSIC-CREDITS.txt"
codesign --force --sign - "$APP"
echo "Built $APP"
