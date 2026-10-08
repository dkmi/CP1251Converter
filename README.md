# CP1251Converter

A small macOS AppKit app that converts a dragged text file from Windows-1251 (CP1251) to UTF-8.

## Requirements

- macOS 13 or later
- Xcode with the macOS SDK

## Build and Run

1. Open `CP1251Converter.xcodeproj` in Xcode.
2. Select the `CP1251Converter` scheme and My Mac destination.
3. Choose Product > Run.

## Usage

1. Drag a CP1251 text file into the drop area.
2. Click **Convert**.

The app overwrites the selected file with its UTF-8 version. Keep a backup of the original when needed.

The application icon is included in `Assets.xcassets/AppIcon.appiconset`.
