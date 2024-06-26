# Adobe Experience Platform Test Utilities (AEPTestUtils) contribution guide

This guide describes the guidelines for contributing to the `AEPTestUtils` library.

Generally, the APIs exposed by `AEPTestUtils` should be considered public APIs and treated with the same level of care in terms of maintenance commitment and breaking changes.

The library is not published as part of Core, as it is internal to Mobile SDK development. Instead, it uses a git tag in the format `testutils-x.y.z`, where `x.y.z` generally follows semantic versioning rules, and its major version matches that of Core. This way, `AEPTestUtils` can be updated independently from Core.

## When making `AEPTestUtils`-only changes

This scenario is usually encountered when making changes to `AEPTestUtils` that are independent of Core.

1. Create a separate development branch off of `main` in the Core repo that will serve as the main staging point for all changes to the `AEPTestUtils` library.
2. Merge all changes into the branch created in the previous step.
3. Merge this branch into the `main` branch. Do not publish or release Core itself.
4. Create a new git tag specifically for `AEPTestUtils` using the format: `testutils-x.y.z`, incrementing the minor version for new features and the patch version for fixes.
    * If a breaking change **must** be made, increment the minor version (as the major version must remain aligned with the current Core major version).

## When making Core + `AEPTestUtils` changes

This scenario is usually encountered when there are breaking changes in Core that affect `AEPTestUtils`.

1. Make the corresponding changes required in `AEPTestUtils` to address the breaking changes and merge them into the same branch where the Core changes are.
2. Once Core is released, create a new git tag specifically for `AEPTestUtils` using the format: `testutils-x.y.z`, incrementing the patch version.

## When developing locally in the Core repository

While external repositories bring in the `AEPTestUtils` dependency using Cocoapods, Core instead uses the local Xcode targets `AEPCoreMocks` and `AEPServicesMocks`. When creating a new source file to be part of `AEPTestUtils`, make sure that:

1. The file goes into the appropriate project directory based on its dependencies.
   * For example, if it has a dependency on `AEPCore`, place it under `AEPCore/Mocks/PublicTestUtils`. If it only has a dependency on `AEPServices`, place it under `AEPServices/Mocks/PublicTestUtils`.
   * If the file has no dependencies on either `AEPServices` or `AEPCore`, place it under `AEPServices/Mocks/PublicTestUtils`.
2. The file is added to the appropriate project target's Build Phases -> Compile Sources list of source files, using the same dependency logic as the previous point.