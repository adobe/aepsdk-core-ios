#!/bin/bash
set -eo pipefail

MODULES="AEPServices AEPCore AEPLifecycle AEPIdentity AEPSignal"
RULESENGINE="AEPRulesEngine"
ALL_MODULES="$MODULES $RULESENGINE"
CURR_DIR="$(pwd)"
PROJECT="$CURR_DIR/AEPCore.xcodeproj"
DERIVED_DATA="$CURR_DIR/build/DerivedData"
SOURCE_PACKAGES="$CURR_DIR/build/SourcePackages"

destination_for() {
  local platform=$1 variant=$2
  case "$platform-$variant" in
    ios-device) echo "generic/platform=iOS" ;;
    ios-simulator) echo "generic/platform=iOS Simulator" ;;
    tvos-device) echo "generic/platform=tvOS" ;;
    tvos-simulator) echo "generic/platform=tvOS Simulator" ;;
  esac
}

archive_target() {
  local project=$1 module=$2 platform=$3 variant=$4
  local suffix=""
  if [ "$variant" = "simulator" ]; then
    suffix="_simulator"
  fi
  xcodebuild archive \
    -project "$project" \
    -scheme "$module" \
    -archivePath "$CURR_DIR/build/$module-$platform$suffix.xcarchive" \
    -destination "$(destination_for "$platform" "$variant")" \
    -derivedDataPath "$DERIVED_DATA" \
    -clonedSourcePackagesDirPath "$SOURCE_PACKAGES" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEBUG_INFORMATION_FORMAT=dwarf-with-dsym
}

archive_own_modules() {
  local platform=$1
  for module in $MODULES; do
    archive_target "$PROJECT" "$module" "$platform" device
    archive_target "$PROJECT" "$module" "$platform" simulator
  done
}

prepare_rulesengine_project() {
  local checkout="$SOURCE_PACKAGES/checkouts/aepsdk-rulesengine-ios"
  local project_dir="$CURR_DIR/build/$RULESENGINE-project"
  local spec="$CURR_DIR/build/$RULESENGINE-project.yml"

  if [ ! -d "$checkout/Sources/AEPRulesEngine" ]; then
    echo "Could not find the resolved AEPRulesEngine sources at $checkout" >&2
    exit 1
  fi
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "xcodegen is required to create the AEPRulesEngine framework archive" >&2
    exit 1
  fi

  cat > "$spec" <<EOF
name: $RULESENGINE
options:
  deploymentTarget:
    iOS: "12.0"
    tvOS: "12.0"
targets:
  $RULESENGINE:
    type: framework
    platform: [iOS, tvOS]
    sources:
      - path: "$checkout/Sources/AEPRulesEngine"
    settings:
      base:
        APPLICATION_EXTENSION_API_ONLY: YES
        BUILD_LIBRARY_FOR_DISTRIBUTION: YES
        DEBUG_INFORMATION_FORMAT: dwarf-with-dsym
        DEFINES_MODULE: YES
        GENERATE_INFOPLIST_FILE: YES
        INSTALL_PATH: "\$(LOCAL_LIBRARY_DIR)/Frameworks"
        PRODUCT_BUNDLE_IDENTIFIER: com.adobe.aep.rulesengine
        SKIP_INSTALL: NO
        SWIFT_VERSION: "5.0"
EOF

  xcodegen generate --spec "$spec" --project "$project_dir" --quiet
  printf '%s\n' "$project_dir/$RULESENGINE.xcodeproj"
}

archive_rulesengine() {
  local platform=$1
  local project
  project=$(prepare_rulesengine_project)
  archive_target "$project" "$RULESENGINE" "$platform" device
  archive_target "$project" "$RULESENGINE" "$platform" simulator
}

build_platform() {
  local platform=$1
  archive_own_modules "$platform"
  archive_rulesengine "$platform"
}

create_xcframeworks() {
  local include_tvos=$1
  for module in $ALL_MODULES; do
    args=(
      -framework "./build/$module-ios_simulator.xcarchive/Products/Library/Frameworks/$module.framework"
      -debug-symbols "$CURR_DIR/build/$module-ios_simulator.xcarchive/dSYMs/$module.framework.dSYM"
    )
    if [ "$include_tvos" = "true" ]; then
      args+=(
        -framework "./build/$module-tvos_simulator.xcarchive/Products/Library/Frameworks/$module.framework"
        -debug-symbols "$CURR_DIR/build/$module-tvos_simulator.xcarchive/dSYMs/$module.framework.dSYM"
      )
    fi
    args+=(
      -framework "./build/$module-ios.xcarchive/Products/Library/Frameworks/$module.framework"
      -debug-symbols "$CURR_DIR/build/$module-ios.xcarchive/dSYMs/$module.framework.dSYM"
    )
    if [ "$include_tvos" = "true" ]; then
      args+=(
        -framework "./build/$module-tvos.xcarchive/Products/Library/Frameworks/$module.framework"
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
