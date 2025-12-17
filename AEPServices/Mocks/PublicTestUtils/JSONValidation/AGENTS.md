# JSONValidation Tool (Maintenance Guide)

This directory contains the source code for the `JSONValidation` utility, a fluent JSON assertion library used throughout the Adobe Experience Platform (AEP) Mobile SDK test suite.

## 1. Purpose

This tool allows tests to compare JSON structures (String, Dictionary, AnyCodable) with granular control over:
- Array ordering (`anyOrder`)
- Type vs Value matching (`typeMatch` vs `exactMatch`)
- Collection sizes (`equalCount`)
- Element presence (`keyMustBeAbsent`)

## 2. Architecture

- **`JSONAssertionBuilder.swift`**: The fluent API entry point. Stores configuration in `NodeConfig`.
- **`ValidationEngine.swift`**: The core logic that traverses the JSON tree and applies rules from `NodeConfig`.
- **`NodeConfig.swift`**: A tree structure that mirrors the JSON hierarchy, storing validation options for each node.
- **`JSONPath.swift`**: A parser and representation for paths like `"items[0].name"`.
- **`AnyCodableComparable.swift`**: Type erasure to allow comparing mixed types (String vs Int vs Bool).

## 3. Testing Changes

This utility is part of the **AEPTestUtils** module.

### How to Run Tests
To test changes to this tool, run the unit tests in `AEPServices/Tests/utility/JSONValidation/`.

### Adding New Features
1.  **Modify `NodeConfig.swift`** to add storage for new options.
2.  **Modify `JSONAssertionBuilder.swift`** to add fluent methods.
3.  **Modify `ValidationEngine.swift`** to implement logic during traversal.
4.  **Add Tests**: Create new test cases in `AEPServices/Tests/utility/JSONValidation/` verifying the new behavior.
5.  **Update Documentation**: Update `Documentation/Testing/JSONValidation.md` if the change adds new capabilities or alters behavior.

## 4. Documentation

- **User Guide**: `Documentation/Testing/JSONValidation.md` (How to *use* the tool).
- **Maintenance**: This file (How to *modify* the tool).
