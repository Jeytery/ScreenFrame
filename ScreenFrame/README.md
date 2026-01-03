# ScreenFrame

ScreenFrame is a macOS SwiftUI utility for wrapping screenshots with polished Apple device frames. Drag screenshots into the app, tweak device/color selections per item, and export everything as framed PNGs (bundled in a timestamped zip archive).

## Project Structure

| File | Role |
| --- | --- |
| `ScreenFrameApp.swift` | SwiftUI entry point that loads `ContentView`. |
| `ContentView.swift` | Primary UI shell (drop zone, list, toolbar, export handling). |
| `DropHint.swift`, `ScreenRow.swift`, `PreviewPanel.swift`, `DeviceFramePreview.swift` | Self-contained SwiftUI views used by `ContentView`. |
| `ScreenItem.swift` | Model representing a dropped screenshot and its chosen device/color. |
| `DeviceProfile.swift` | Device catalog definitions (`DeviceProfile`, `DeviceColor`, `FrameStyle`, etc.). |
| `FrameRenderer.swift` | Renders a screenshot into a device frame and returns PNG data. |
| `GeometryHelpers.swift` | Aspect-fit, scaling, and coordinate helper functions shared by previews and rendering. |
| `ZipUtility.swift` | Wraps `/usr/bin/zip` to archive exported PNGs without the parent directory. |
| `Assets.xcassets` | Device frame PNGs (names referenced in `DeviceLibrary`). |

## Data Flow Overview

1. **Drop / Load**
   - `ContentView.handleDrop` reads file URLs from `NSItemProvider`, loads `NSImage`, and creates a `ScreenItem`.
   - `DeviceLibrary.matchingDevice` uses image size to guess a device profile; first color is selected by default.

2. **Editing**
   - Each row (`ScreenRow`) lets you change the device and color; the binding ensures `ScreenItem` stays in sync.
   - Color picker content is derived from the currently selected device, enforcing valid combinations.

3. **Preview**
   - `PreviewPanel` hosts `DeviceFramePreview`, which mirrors the final render in SwiftUI.
   - Preview math uses helpers in `GeometryHelpers.swift` to mimic the renderer’s layout.

4. **Export**
   - `downloadAll` opens an `NSOpenPanel`, then `exportItems` renders every item via `FrameRenderer.pngData`.
   - PNGs are written into a temp folder, zipped by `ZipUtility`, and the archive is moved to the chosen directory.

## Extending the Device Catalog

1. Add the frame PNG(s) to `Assets.xcassets` and note their names.
2. Create a new `DeviceColor` constant (frame asset name must match the `.imageset`).
3. Append a `DeviceProfile` to `DeviceLibrary.catalog`:
   - Fill dimensions (`displaySize`), `cornerRadius`, and supported `colors`.
   - Provide `FrameStyle` with normalized `ScreenInsets`, `screenCornerRadiusRatio`, and `contentScale`.
4. Optionally adjust `matchingDevice` if you need weighted logic for device selection.

## Rendering Notes

- Rendering is AppKit-based (`NSImage` drawing) so screenshots can be exported even without previews showing.
- Screen rect math happens twice (preview and render). Keep `GeometryHelpers` consistent if you tweak anything.
- Errors thrown by `FrameRenderer` or `ZipUtility` bubble up to `exportItems`, which sets `exportError` to surface an alert.

## Running & Debugging

1. Open `ScreenFrame.xcodeproj` in Xcode 16 or newer (Project deployment target is macOS 14+ / Swift 5).
2. Build/run the `ScreenFrame` target. The app uses SwiftUI previews; turn them on in `ContentView` if desired.
3. When adding files, ensure they’re part of the main target (Xcode should auto-include, but double-check the “Target Membership” box).

## Tips & Gotchas

- Asset names are used verbatim (`NSImage.Name`). Typos result in a missing-frame warning in previews and runtime errors during export.
- `ZipUtility` shells out to `/usr/bin/zip`; avoid sandbox restrictions that block process launches.
- The export process runs on the main actor intentionally—switch to detached tasks if you plan to support large batches and background progress UI.
