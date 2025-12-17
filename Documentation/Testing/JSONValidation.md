# JSON Validation Tool Guide

This guide explains how to use the `JSONValidation` tool for flexible and powerful JSON assertions in unit tests.

## 1. Core Concepts & Usage

The tool uses a fluent builder pattern to assert equality between expected and actual JSON values, with granular control over specific paths.

### Basic Usage
```swift
assertJSON(expected: expectedJSON, actual: actualJSON)
    .anyOrder(at: "items[*]")         // Allow array elements in any order
    .typeMatch(at: "metadata.date")   // Check type only (ignore value)
    .exactMatch(at: "metadata.id")    // Enforce strict value equality
    .validate()                       // Run assertions
```
> **Tip:** Place each builder method on a new line to improve readability and make it easier to scan the validation logic.

### Coding Conventions & Style
- **Keep chains readable**: Put each builder method on its own line.
- **Prefer root shorthand**: When applying an option at the root, omit `at:` (variadic overloads allow “no paths”).
- **Prefer exception-based configuration**: Configure only what’s special (e.g., “allow any order here”, “type match this field”) and rely on defaults elsewhere.

```swift
assertJSON(expected: e, actual: a)
    .equalCount(scope: .subtree)   // Root + all descendants
    .validate()
```

```swift
assertJSON(expected: e, actual: a)
    .equalCount(at: "users")       // Only `users` collection count is strict
    .validate()
```

### Default Behavior
Unless configured otherwise, `assertJSON` enforces the following validation logic:
1.  **Exact Value Matching**: Values must match exactly (type and literal value).
    *   *Migration Note*: Users of `assertTypeMatch` must explicitly add `.typeMatch(...)`.
2.  **Strict Array Ordering**: Array elements must match in the given order.
3.  **Extensible Collections**: `actual` can contain more keys/elements than `expected` (subset match).
    *   To enforce exact counts, use `.equalCount(...)`.

### Supported Input Types

The `expected` and `actual` parameters accept any type conforming to `AnyCodableComparable`:
- **Strings**: Automatically parsed as JSON if possible; otherwise treated as raw strings.
- **Dictionaries**: `[String: Any]` (Standard JSON objects).
- **NetworkRequest**: Automatically extracts and parses `connectPayload`.
- **AnyCodable**: Wrappers for type-erased JSON data (use this to wrap Arrays or other types).
- **Optionals**: `nil` is handled gracefully.

### JSONPath Syntax
Paths are strings specifying location within the JSON structure:
- **Root**: `JSONPath.root` or omitted in some APIs.
- **Properties**: `"user.name"`
- **Array Indices**: `"items[0]"`
- **Wildcards**:
    - `"items[*]"`: All elements in the `items` array.
    - `"config.*"`: All keys in the `config` object.

### Scope
- **`.singleNode`**: Applies only to the specific node at the path.
- **`.subtree`**: Applies to the node and all its descendants.
  - Example: `.typeMatch(scope: .subtree)` on root relaxes validation for the entire JSON to check types only.

---

## 2. Builder Capabilities Reference

These methods are available on the builder returned by `assertJSON(...)`.

### Array Ordering
| Method | Description |
| :--- | :--- |
| `.anyOrder(at: ...)` | **Relaxation**: Array elements at the path can be in any order. |
| `.strictOrder(at: ...)` | **Restriction**: Array elements must be in the exact order (default behavior). Use to override a broader `.anyOrder` setting. |

> **Path Usage for Ordering**:
> *   `"items[*]"`: Applies to **all elements** (e.g. all items unordered).
> *   `"items[0]"`: Applies to a **specific element** (e.g. only first item unordered).
> *   `"items"`: Applies to the **list container** (does NOT affect element ordering).

### Collection Counts
| Method | Description |
| :--- | :--- |
| `.equalCount(at: ...)` | **Restriction**: Arrays/Objects must have the exact same number of elements as expected. (Default: actual can have extra elements). |
| `.flexibleCount(at: ...)` | **Relaxation**: Actual arrays/objects can have more elements than expected (default behavior). |
| `.elementCount(_ count: Int, at: ...)` | **Validation**: Enforce a specific element count at a path. |

### Value Matching
| Method | Description |
| :--- | :--- |
| `.exactMatch(at: ...)` | **Restriction**: Types and literal values must match (default behavior). |
| `.typeMatch(at: ...)` | **Relaxation**: Only types must match; literal values can differ. Useful for timestamps, IDs, etc. |
| `.valueNotEqual(at: ...)` | **Validation**: Fails if the values ARE equal. Useful for checking state changes. |

### Structure
| Method | Description |
| :--- | :--- |
| `.keyMustBeAbsent(at: ...)` | **Validation**: The specified path must NOT exist in the actual JSON. |

### Terminal Operations
| Method | Description |
| :--- | :--- |
| `.validate()` | Runs assertions and reports failures to XCTest. |
| `.check() -> Bool` | Returns `true` if valid, `false` otherwise (no assertions). |
| `.validateWithResult() -> ValidationResult` | Returns detailed result object. |

---

## 3. Migration Guide (Deprecated `MultiPathConfig` -> Fluent Builder)

The old `pathOptions` array using `MultiPathConfig` structs has been removed. Existing code using these types will fail to compile. Use the chainable methods on `assertJSON` instead.

### Step 0: Remove Protocol Conformance
If your test class conforms to `AnyCodableAsserts`, remove it. The new assertion methods are available directly as `XCTestCase` extensions.

**Old:**
```swift
class MyTests: XCTestCase, AnyCodableAsserts { ... }
```

**New:**
```swift
class MyTests: XCTestCase { ... }
```

### General Mapping Rules

| Old `MultiPathConfig` | New Builder Method |
| --------------------- | ------------------ |
| `AnyOrderMatch` | `.anyOrder(at: ...)` |
| `CollectionEqualCount` | `.equalCount(at: ...)` |
| `ElementCount` | `.elementCount(count, at: ...)` |
| `KeyMustBeAbsent` | `.keyMustBeAbsent(at: ...)` |
| `ValueNotEqual` | `.valueNotEqual(at: ...)` |
| `ValueExactMatch` | `.exactMatch(at: ...)` |
| `ValueTypeMatch` | `.typeMatch(at: ...)` |

### 1:1 Migration Examples

#### 1. Exact Equality (assertEqual)
**Old:**
```swift
assertEqual(expected: e, actual: a)
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .equalCount(scope: .subtree)
    .validate()
```

#### 2. Type Match Only (assertTypeMatch)
**Old:**
```swift
assertTypeMatch(expected: e, actual: a)
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .typeMatch(scope: .subtree)
    .validate()
```

#### 3. Any Order Match
**Old:**
```swift
assertExactMatch(expected: e, actual: a, pathOptions: [
    AnyOrderMatch(paths: "items", "tags")
])
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .anyOrder(at: "items[*]", "tags[*]") // Entire arrays unordered
    .anyOrder(at: "priority_list[0]")    // Only the first expected item is order-independent
    .validate()
```

#### 4. Collection Equal Count
**Old:**
```swift
assertExactMatch(expected: e, actual: a, pathOptions: [
    CollectionEqualCount(paths: "users")
])
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .equalCount(at: "users")
    .validate()
```

#### 5. Element Count
**Old:**
```swift
assertExactMatch(expected: e, actual: a, pathOptions: [
    ElementCount(paths: "config", requiredCount: 5)
])
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .elementCount(5, at: "config")
    .validate()
```

#### 6. Type Match Only (Ignore Literal Value)
**Old:**
```swift
assertExactMatch(expected: e, actual: a, pathOptions: [
    ValueTypeMatch(paths: "timestamp", "uuid")
])
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .typeMatch(at: "timestamp", "uuid")
    .validate()
```

#### 7. Complex Combination
**Old:**
```swift
assertExactMatch(expected: e, actual: a, pathOptions: [
    AnyOrderMatch(paths: "events"),
    ValueTypeMatch(paths: "events[*].timestamp"),
    KeyMustBeAbsent(paths: "events[*].legacy_id")
])
```
**New:**
```swift
assertJSON(expected: e, actual: a)
    .anyOrder(at: "events[*]")
    .typeMatch(at: "events[*].timestamp")
    .keyMustBeAbsent(at: "events[*].legacy_id")
    .validate()
```

---

## 4. The JSONPath Paradigm

### Root Reference
- Root can be expressed by **omitting the `at:` paths** in variadic overloads (e.g. `.typeMatch(scope: .subtree)`).
- Example: `.anyOrder(at: "[*]")` applies to all elements in the root array.
- `nil` paths in the old API represented root; `JSONPath.root` is the explicit new equivalent.

### Wildcards (`*`)
- Used to apply rules to all children of a node.
- **Key difference**:
    - `path: "items"` refers to the array *container* itself (e.g., used for `.equalCount`).
    - `path: "items[*]"` refers to *every element inside* the array (e.g., used for `.anyOrder` or `.typeMatch` on items).
    - **Requirement**: Applying options to the container (e.g. `"items"`) does not affect element ordering.