# Samplem SwiftUI app (macOS)

A small native app to drag-and-drop a sample folder and run the CLI with options.

## Build (XcodeGen)

1. Install XcodeGen:
```
brew install xcodegen
```
2. Generate the Xcode project:
```
cd /Users/valentin.binjacar/mirakl/samplem/swiftui
xcodegen generate
```
3. Open `Samplem.xcodeproj` in Xcode and Build/Run.

## Requirements
- macOS 12+
- `samplem` installed and on PATH (e.g. via Homebrew tap) or place absolute path in `ContentView.runSamplem()`.

## Notes
- The app calls the CLI:
  - `samplem repack --path <folder> [--normalize|--no-normalize] [--trim|--no-trim] --layout {keep,flat-prefix,flat}`
- Adjust PATH in `runSamplem()` if needed.
