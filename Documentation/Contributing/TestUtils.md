# Adobe Experience Platform Test Utilities (AEPTestUtils) contribution guide

This guide describes the guidelines for contributing to the `AEPTestUtils` library.

Generally, the APIs exposed by `AEPTestUtils` should be considered public APIs and treated with the same level of care in terms of maintenance commitment and breaking changes.

The library is not published as part of Core, as it is internal to Mobile SDK development. Instead, it uses a git tag in the format `testutils-x.y.z`, where `x.y.z` generally follows semantic versioning rules, and its major version matches that of Core. This way, `AEPTestUtils` can be updated independently from Core. This pod isn't available on CocoaPods and can only be referenced using its GitHub URL:

```ruby
pod 'AEPTestUtils', :git => 'https://github.com/adobe/aepsdk-core-ios.git', :tag => 'testutils-5.0.3'
```

## When making `AEPTestUtils`-only changes

This scenario is usually encountered when making changes to `AEPTestUtils` that are independent of Core.

1. Create a separate development branch off of `main` in the Core repo that will serve as the main staging point for all changes to the `AEPTestUtils` library.
2. Merge all changes into the branch created in the previous step.
3. Merge this branch into the `main` branch. Do not publish or release Core itself.
4. Create a new git tag specifically for `AEPTestUtils` using the format: `testutils-x.y.z`, incrementing the minor version for new features and the patch version for fixes.
    * Breaking changes in `AEPTestUtils` should be avoided whenever possible. However, if a breaking change must be implemented, increment the minor version (the major version must remain aligned with the current Core major version).

## When making Core + `AEPTestUtils` changes

This scenario is usually encountered when there are changes in Core that affect `AEPTestUtils`.

1. Make the necessary changes in `AEPTestUtils` to address the updates and merge them into the same branch where the Core changes are.
2. Update the `AEPTestUtils.podspec` to reflect the new Core and Services dependency versions.
3. Once Core is released, create a new Git tag specifically for `AEPTestUtils` using the format `testutils-x.y.z`, incrementing the patch version.

## When developing locally in the Core repository

While external repositories bring in the `AEPTestUtils` dependency using CocoaPods, Core uses local Xcode targets: `AEPCoreMocks` and `AEPServicesMocks` to manage this dependency. When adding a new source file to `AEPTestUtils`, follow these steps:

1. Place the file in the appropriate project directory based on its dependencies:
   * If the file depends on `AEPCore`, place it in `AEPCore/Mocks/PublicTestUtils`.
   * If the file depends only on `AEPServices`, place it in `AEPServices/Mocks/PublicTestUtils`.
   * If the file has no dependencies on either `AEPServices` or `AEPCore`, place it in `AEPServices/Mocks/PublicTestUtils`.
   * If the file is not intended to be included in `AEPTestUtils`, place it in its respective `Mocks` directory but outside of `PublicTestUtils`.
   
2. Add the file to the correct project target's **Build Phases** -> **Compile Sources** list:
   * If the file is under `AEPServices/Mocks/PublicTestUtils`, add it to **both** the `AEPServicesMocks` and `AEPCoreMocks` frameworks.
   * If the file is under `AEPCore/Mocks/PublicTestUtils`, add it **only** to the `AEPCoreMocks` framework.
