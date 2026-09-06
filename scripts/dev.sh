#!/usr/bin/env bash
# ABOUTME: Development convenience script for VibeFloor.
# ABOUTME: Usage: ./scripts/dev.sh [build|run|test|clean]

set -e

PROJECT="FactoryFloor.xcodeproj"
SCHEME="FactoryFloor"
TEST_SCHEME="FactoryFloorTests"
APP_NAME="VibeFloor"
BUILD_DIR="build/debug/derived"
APP_PATH="$BUILD_DIR/Build/Products/Debug/$APP_NAME.app"
SPM_CACHE="$HOME/Library/Caches/factoryfloor/spm"
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
GHOSTTY_RESOURCES="ghostty/zig-out/share"

ensure_ghostty_resources() {
  if [ ! -d "$GHOSTTY_RESOURCES/terminfo" ] || [ ! -d "$GHOSTTY_RESOURCES/ghostty" ]; then
    echo "error: Ghostty resources not found at $GHOSTTY_RESOURCES/"
    echo "       Build the xcframework first: cd ghostty && zig build"
    exit 1
  fi
}

ensure_monaco_editor() {
  # Always delegate: build-editor.sh self-skips when the output is newer than
  # every source file. Gating on existence here instead would silently ship a
  # stale bundle after editor/src changes.
  bash scripts/build-editor.sh
}

case "${1:-build}" in
  build)
    ensure_ghostty_resources
    ensure_monaco_editor
    xcodegen generate
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
      -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_CACHE" \
      -skipPackagePluginValidation \
      CURRENT_PROJECT_VERSION="$BRANCH" build
    ;;
  run)
    shift 2>/dev/null || true
    pkill -xf ".*/Contents/MacOS/$APP_NAME" 2>/dev/null || true
    sleep 0.5
    if [ -n "${1:-}" ]; then
      DIR=$(cd "$1" && pwd)
      open "$APP_PATH" --args "$DIR"
    else
      open "$APP_PATH"
    fi
    ;;
  full)
    shift 2>/dev/null || true
    echo "==> Building and running VibeFloor..."
    xcodegen generate
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
      -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_CACHE" \
      CURRENT_PROJECT_VERSION="$BRANCH" build
    pkill -xf ".*/Contents/MacOS/$APP_NAME" 2>/dev/null || true
    sleep 0.5
    if [ -n "${1:-}" ]; then
      DIR=$(cd "$1" && pwd)
      open "$APP_PATH" --args "$DIR"
    else
      open "$APP_PATH"
    fi
    ;;
  br)
    shift 2>/dev/null || true
    ensure_ghostty_resources
    ensure_monaco_editor
    xcodegen generate
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug \
      -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_CACHE" \
      -skipPackagePluginValidation \
      CURRENT_PROJECT_VERSION="$BRANCH" build
    pkill -xf ".*/Contents/MacOS/$APP_NAME" 2>/dev/null || true
    sleep 0.5
    if [ -n "${1:-}" ]; then
      DIR=$(cd "$1" && pwd)
      open "$APP_PATH" --args "$DIR"
    else
      open "$APP_PATH"
    fi
    ;;
  test)
    ensure_ghostty_resources
    ensure_monaco_editor
    xcodegen generate
    xcodebuild -project "$PROJECT" -scheme "$TEST_SCHEME" -configuration Debug \
      -derivedDataPath "$BUILD_DIR" -clonedSourcePackagesDirPath "$SPM_CACHE" \
      -skipPackagePluginValidation test
    ;;
  release)
    RELEASE_DIR="build/release-local/derived"
    ensure_ghostty_resources
    ensure_monaco_editor
    xcodegen generate
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
      -derivedDataPath "$RELEASE_DIR" -clonedSourcePackagesDirPath "$SPM_CACHE" \
      -skipPackagePluginValidation \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGN_STYLE=Manual \
      ENABLE_HARDENED_RUNTIME=YES \
      CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
      CODE_SIGN_ENTITLEMENTS=Resources/ff2-local.entitlements \
      OTHER_CODE_SIGN_FLAGS="--options=runtime" \
      build
    APP_BUNDLE="$RELEASE_DIR/Build/Products/Release/VibeFloor.app"
    echo "==> Release build at: $APP_BUNDLE"
    if [ "${2:-}" = "--run" ]; then
      pkill -xf ".*/Contents/MacOS/VibeFloor" 2>/dev/null || true
      sleep 0.5
      open "$RELEASE_DIR/Build/Products/Release/VibeFloor.app"
    fi
    ;;
  clean)
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Debug clean 2>/dev/null || true
    rm -rf build/debug build/release-local "$SPM_CACHE"
    ;;
  *)
    echo "Usage: ./scripts/dev.sh [command] [directory]"
    echo ""
    echo "  build    Build (debug)"
    echo "  run      Kill and relaunch (optionally with a directory)"
    echo "  br       Build and run"
    echo "  full     Build and run (same as br)"
    echo "  test     Run tests"
    echo "  release  Build Release matching CI (hardened runtime)"
    echo "  release --run  Build and run Release"
    echo "  clean    Clean build artifacts"
    ;;
esac
