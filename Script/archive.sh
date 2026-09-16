#!/bin/bash
set -eo pipefail

MODULES="AEPServices AEPCore AEPLifecycle AEPIdentity AEPSignal"
RULESENGINE="AEPRulesEngine"
ALL_MODULES="$MODULES $RULESENGINE"
CURR_DIR="$(pwd)"

destination_for() {
  local platform=$1 variant=$2
  case "$platform-$variant" in
    ios-device) echo "generic/platform=iOS" ;;
    ios-simulator) echo "generic/platform=iOS Simulator" ;;
    tvos-device) echo "generic/platform=tvOS" ;;
    tvos-simulator) echo "generic/platform=tvOS Simulator" ;;
  esac
}

archive_own_modules() {
  local platform=$1
  for module in $MODULES; do
    xcodebuild archive -scheme "$module" -archivePath "./build/$module-$platform.xcarchive" -destination "$(destination_for "$platform" device)" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
    xcodebuild archive -scheme "$module" -archivePath "./build/$module-${platform}_simulator.xcarchive" -destination "$(destination_for "$platform" simulator)" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES
  done
}

archive_rulesengine() {
  local platform=$1
  local checkout
  checkout=$(find ~/Library/Developer/Xcode/DerivedData -maxdepth 6 -type d -ipath "*SourcePackages/checkouts*rulesengine*" -print -quit 2>/dev/null)
  if [ -z "$checkout" ]; then
    echo "Could not find resolved AEPRulesEngine checkout" >&2
    exit 1
  fi
  # Upstream AEPRulesEngine doesn't declare its library as dynamic; without this patch
  # xcodebuild archive produces a raw object instead of a .framework bundle.
  sed -i '' 's#\.library(name: "AEPRulesEngine", targets: \["AEPRulesEngine"\])#.library(name: "AEPRulesEngine", type: .dynamic, targets: ["AEPRulesEngine"])#' "$checkout/Package.swift"
  (cd "$checkout" && xcodebuild archive -scheme "$RULESENGINE" -archivePath "$CURR_DIR/build/$RULESENGINE-$platform.xcarchive" -destination "$(destination_for "$platform" device)" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES)
  (cd "$checkout" && xcodebuild archive -scheme "$RULESENGINE" -archivePath "$CURR_DIR/build/$RULESENGINE-${platform}_simulator.xcarchive" -destination "$(destination_for "$platform" simulator)" SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES)
}

build_platform() {
  local platform=$1
  # AEPCore.xcodeproj and Package.swift coexisting makes xcodebuild's scheme resolution
  # ambiguous, so the legacy project is moved aside for the duration of this build.
  mv AEPCore.xcodeproj .AEPCore.xcodeproj.bak
  mv AEPCore.xcworkspace .AEPCore.xcworkspace.bak
  trap 'mv .AEPCore.xcodeproj.bak AEPCore.xcodeproj; mv .AEPCore.xcworkspace.bak AEPCore.xcworkspace' EXIT
  archive_own_modules "$platform"
  archive_rulesengine "$platform"
}

create_xcframeworks() {
  local include_tvos=$1
  for module in $ALL_MODULES; do
    args=(
      -framework "./build/$module-ios_simulator.xcarchive/Products/usr/local/lib/$module.framework"
      -debug-symbols "$CURR_DIR/build/$module-ios_simulator.xcarchive/dSYMs/$module.framework.dSYM"
    )
    if [ "$include_tvos" = "true" ]; then
      args+=(
        -framework "./build/$module-tvos_simulator.xcarchive/Products/usr/local/lib/$module.framework"
        -debug-symbols "$CURR_DIR/build/$module-tvos_simulator.xcarchive/dSYMs/$module.framework.dSYM"
      )
    fi
    args+=(
      -framework "./build/$module-ios.xcarchive/Products/usr/local/lib/$module.framework"
      -debug-symbols "$CURR_DIR/build/$module-ios.xcarchive/dSYMs/$module.framework.dSYM"
    )
    if [ "$include_tvos" = "true" ]; then
      args+=(
        -framework "./build/$module-tvos.xcarchive/Products/usr/local/lib/$module.framework"
        -debug-symbols "$CURR_DIR/build/$module-tvos.xcarchive/dSYMs/$module.framework.dSYM"
      )
    fi
    args+=(-output "./build/$module.xcframework")
    xcodebuild -create-xcframework "${args[@]}"
  done
}

case "$1" in
  build-ios) build_platform ios ;;
  build-tvos) build_platform tvos ;;
  create-xcframeworks) create_xcframeworks true ;;
  create-xcframeworks-ios) create_xcframeworks false ;;
  *) echo "Usage: $0 {build-ios|build-tvos|create-xcframeworks|create-xcframeworks-ios}" >&2; exit 1 ;;
esac
