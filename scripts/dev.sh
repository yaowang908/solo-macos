#!/bin/bash
# Build the Debug configuration into ./build and launch it. Solo's
# single-instance behavior quits any other running copy (e.g. the
# Homebrew release in /Applications) automatically.
set -euo pipefail
cd "$(dirname "$0")/.."
xcodebuild -project Solo.xcodeproj -scheme Solo -configuration Debug \
  -destination 'platform=macOS' -derivedDataPath build build
open build/Build/Products/Debug/Solo.app
