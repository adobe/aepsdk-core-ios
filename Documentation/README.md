# Development setup

## Requirements

- Xcode 11.x
- Swift 5.x
- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)

## SwiftFormat & SwfitLint

Before you commit code, please make sure your code changes have passed the format/lint check using `make` commands 
- `make checkFormat`  
- `make lint`

### Xcode Integration


```Shell
cd ${PROJECT_DIR}
if which swiftlint >/dev/null; then
  swiftlint
else
  echo "error: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
if which swiftformat >/dev/null; then
   swiftformat .
else
echo "error: SwiftFormat not installed, download from https://github.com/nicklockwood/SwiftFormat"
fi
```

Adding above script to `Build Phase` of each project target ([link](https://github.com/adobe/aepsdk-core-ios/blob/3f995fb6d296d004ffff714c49640440da0ef48e/AEPCore.xcodeproj/project.pbxproj#L1936)), then whenever you compile Xcode project/targets, this script will help you:
- Format source code automatically 
- Show `SwiftLint` warnings/errors in IDE

### Make command

You can also run `make` command manually:

- `make format` to format source code
- `make lint-autocorrect` to automatically correct part of `lint` warnings/errors

# AEP SDK Swift Style Guide

[Doc](./StyleGuide.md)

