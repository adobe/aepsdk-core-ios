#!/bin/bash

# make this script executable from terminal:
# chmod u+x api-check.sh

set -e

IOS_TRIPLE="arm64-apple-ios12.0"
TVOS_TRIPLE="arm64-apple-tvos12.0"

parse_modules_from_package() {
    if [ ! -f "Package.swift" ]; then
        echo "Package.swift not found."
        exit 1
    fi
    swift package dump-package | jq -r '.products[] | select(.type | has("library")) | .name'
}

build_and_dump() {
    local module=$1
    local platform=$2
    local output_file=$3
    local TRIPLE
    local SDK
    local SDK_PATH

    case "$platform" in
        ios) TRIPLE=$IOS_TRIPLE; SDK="iphoneos" ;;
        tvos) TRIPLE=$TVOS_TRIPLE; SDK="appletvos" ;;
        *) echo "Unsupported platform: $platform"; exit 1 ;;
    esac

    SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)
    
    # Build in release mode as debug mode dumps non public APIs.
    if ! swift build -c release --sdk "$SDK_PATH" --triple "$TRIPLE" -Xswiftc -enable-library-evolution > /dev/null 2>&1; then
        echo "Build failed."
        exit 1
    fi
        
    swift api-digester -sdk "$SDK_PATH" -dump-sdk -module "$module" \
        -target "$TRIPLE" -avoid-location -avoid-tool-args -abort-on-module-fail -swift-version 5 -I .build/release/Modules \
        -abi -o "$output_file"
}

run_api_digester() {
    local mode="$1"
    local flag
    local output_file
    local output

    if [[ "$mode" == "abi" ]]; then
        flag="-abi"
    else
        flag=""
    fi

    output_file=$(mktemp)

    swift api-digester -sdk "$SDK_PATH" -target "$TRIPLE" -swift-version 5 -diagnose-sdk -print-module \
         --input-paths "$api_file" --input-paths "$sdk_file" $flag -o "$output_file"

    output=$(sed '/^\s*$/d; /^\/\*/d' "$output_file")
    if [[ -n "$output" ]]; then
        echo "Error in [$module][$platform]: $mode differences found"
        echo "$output"
        exit 1    
    fi
}

check_api_diff() {
    local module=$1
    local platform=$2
    local sdk_file=$3
    local api_file=$4
    local SDK
    local SDK_PATH
    local diff_output

    case "$platform" in
        ios) SDK="iphoneos" ;;
        tvos) SDK="appletvos" ;;
        *) echo "Unsupported platform: $platform"; exit 1 ;;
    esac

    SDK_PATH=$(xcrun --sdk "$SDK" --show-sdk-path)

    # Check for API differences
    run_api_digester "api"

    # Check for ABI differences
    run_api_digester "abi"

    # Check for file content differences
    if ! diff_output=$(diff "$api_file" "$sdk_file" 2>&1); then
        echo "Error in [$module][$platform]: API.json file changed"
        echo "$diff_output"
        exit 1
    fi

    echo "[$module][$platform]: No API changes" 
}

run_for_module() {
    local module=$1
    local temp_file=".build/$module-$PLATFORM.json"
    local api_file="API/$module-$PLATFORM.json"

    if [ "$ACTION" == "check" ]; then
        build_and_dump "$module" "$PLATFORM" "$temp_file"
        check_api_diff "$module" "$PLATFORM" "$temp_file" "$api_file"
    elif [ "$ACTION" == "dump" ]; then
        mkdir -p "API"
        build_and_dump "$module" "$PLATFORM" "$api_file"
    fi
}

run_for_all_modules() {
    local modules
    modules=$(parse_modules_from_package)
    for module in $modules; do
        run_for_module "$module"
    done
}

# Process input arguments and execute based on parsed parameters
ACTION=""
MODULE=""
PLATFORM=""
while [ "$1" != "" ]; do
    case $1 in
        --check) ACTION="check" ;;
        --dump) ACTION="dump" ;;
        --module)
            shift
            MODULE=$1
            if [ -z "$MODULE" ]; then
                echo "Error: No module specified with --module."
                exit 1
            fi
            ;;
        --platform)
            shift
            PLATFORM=$1
            if [[ "$PLATFORM" != "ios" && "$PLATFORM" != "tvos" ]]; then
                echo "Error: Invalid platform specified. Use ios or tvos."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [--check | --dump] [--module <module_name>] [--platform <ios|tvos>]"
            echo "Note: If --module is not specified, the script will run for all modules."
            exit 1
            ;;
    esac
    shift
done

if [ -z "$ACTION" ]; then
    echo "Error: No action specified. Use --check or --dump."
    exit 1
fi

if [ -z "$PLATFORM" ]; then
    echo "Error: No platform specified. Use --platform ios or --platform tvos."
    exit 1
fi

if [ -n "$MODULE" ]; then
    run_for_module "$MODULE"
else
    run_for_all_modules
fi
