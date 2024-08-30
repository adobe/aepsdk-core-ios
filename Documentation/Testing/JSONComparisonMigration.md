# JSON comparison API explainer and examples

## Overview

Migrating existing test cases to use the JSON comparison APIs enables powerful and customizable validation for JSON payloads. This document explains how to best use the APIs and covers most migration cases.

## API Behavior and Best Practices

There are three main APIs available for JSON comparison: `assertEqual`, `assertExactMatch`, and `assertTypeMatch`.

### When to Use Each API

1. `assertEqual`: Use this API when you need exact equality, meaning the JSON structure must be identical, and both the types and values of each node must be the same.
2. `assertExactMatch` and `assertTypeMatch`: Use these APIs when you need more flexibility, allowing for customizable comparisons between the expected and actual JSON payloads.
   - `assertExactMatch`: Uses exact value validation for all nodes by default. When comparing a node's value, both the data type and the actual value must match.
   - `assertTypeMatch`: Uses value type validation by default. When comparing a node's value, only the data types need to match; the actual values do not have to be the same.

`assertEqual` example

Before
```swift
let event: [String: Any] = ["type": "edge", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual(2, flattenedEventData.count)
XCTAssertEqual("edge", flattenedEventData["type"]) 
XCTAssertEqual(123, flattenedEventData["key1"])
```

After
```swift
let expected = """{ "type": "edge", "key1": 123 }"""
assertEqual(expected: expected, actual: event)
```

`assertExactMatch` example

Before
```swift
let event: [String: Any] = ["type": "edge", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual("edge", flattenedEventData["type"]) 
XCTAssertEqual(123, flattenedEventData["key1"])
```

After
```swift
let expected = """{ "type": "edge", "key1": 123 }"""
assertExactMatch(expected: expected, actual: event)
```

`assertTypeMatch` example

Before
```swift
let event: [String: Any] = ["timestamp": "2024-08-06T22:45:26Z", "ECID": "abc123"]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertNotNil(flattenedEventData["key1"])
XCTAssertNotNil(flattenedEventData["timestamp"])
```

After
```swift
let expected = """{ "timestamp": "STRING_TYPE", "ECID": "STRING_TYPE" }""" // "STRING_TYPE" is just a value convention - the only requirement is that the value type is the one you want to validate
assertTypeMatch(expected: expected, actual: event)
```

#### Path Options

Both APIs allow for passing in any number of path options, which are customizations you can apply to the JSON comparison logic. The following options are available:

- **Multiple paths** can be used simultaneously.
- **Multiple path options** are applied sequentially, and if an option overrides an existing one, the overriding occurs in the order the path options are specified.

- `AnyOrderMatch`: Array elements from `expected` may match elements from `actual` regardless of index position. When combining any position option indexes and standard indexes, standard indexes are validated first.
- `CollectionEqualCount`: Collections (dictionaries and/or arrays) must have the same number of elements.
- `ElementCount`: The given number of elements (dictionary keys and array elements) must be present.
- `KeyMustBeAbsent`: `actual` must not have the key name specified.
- `ValueNotEqual`: Values must have the same type but the literal values must not be equal.
- `ValueExactMatch`: Values must have the same type and literal value.
- `ValueTypeMatch`: Values must have the same type but their literal values can be different.

Path option usage example
```swift
assertExactMatch(
    expected: expected, 
    actual: actual, 
    pathOptions: KeyMustBeAbsent(paths: "key1"), ValueTypeMatch(paths: "key1.key2")
```

-------------------------

## Migration tips

Migrating from property-by-property validation — such as flattened dictionary or manual property traversal implementations — is straightforward, as the default behavior of the APIs and the customizable path options are designed to support a 1:1 replacement.

**Flattened map example**
```swift
let requestBody = resultNetworkRequests[0].getFlattenedBody()
XCTAssertEqual(14, requestBody.count)
XCTAssertEqual(true, requestBody["meta.konductorConfig.streaming.enabled"] as? Bool)
XCTAssertEqual("value", requestBody["events[0].xdm.test.key"] as? String)
XCTAssertEqual("value", requestBody["events[0].data.key"] as? String)
XCTAssertEqual("app", requestBody["xdm.implementationDetails.environment"] as? String)
XCTAssertEqual("\(MobileCore.extensionVersion)+\(Edge.extensionVersion)", requestBody["xdm.implementationDetails.version"] as? String)
XCTAssertEqual(EXPECTED_BASE_PATH, requestBody["xdm.implementationDetails.name"] as? String)
```

**Manual property traversal example**
```swift
let executeJson = JSON(parseJSON: self.prettify(executeDictionary))
XCTAssertEqual(executeJson["mboxes"][0]["index"].intValue, 0)
XCTAssertEqual(executeJson["mboxes"][0]["name"].stringValue, "t_test_01")
XCTAssertEqual(1, executeJson["mboxes"][0]["profileParameters"].count)
XCTAssertEqual(executeJson["mboxes"][0]["profileParameters"]["name"].stringValue, "Smith")
XCTAssertEqual(1, executeJson["mboxes"][0]["parameters"].count)
XCTAssertEqual(executeJson["mboxes"][0]["parameters"]["mbox-parameter-key1"].stringValue, "mbox-parameter-value1")
```

Each section below explains the key pattern to look for in your test case when migrating to the equivalent JSON comparison API usage.

### Equals validation

#### Key pattern

1. Use of flattened dictionary count.
2. Use of assert equals on all values for exact matches.

Before
```swift
// Example event payload
let event: [String: Any] = ["type": "edge", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual(2, flattenedEventData.count) // (Key pattern 1.) Flattened dictionary count
XCTAssertEqual("edge", flattenedEventData["type"]) // (Key pattern 2.)
XCTAssertEqual(123, flattenedEventData["key1"]) // (Key pattern 2.)
```

After
```swift
let expected = """{ "type": "edge", "key1": 123 }"""
assertEqual(expected: expected, actual: event)
```

This is commonly encountered when an exact validation of all values in a JSON payload is required, with no extensible collections. Use `assertEquals`, which is essentially equivalent to a collection equals comparison.

### Default value exact vs type match

The only difference between the two APIs, `assertExactMatch` and `assertTypeMatch`, is that the default value validation logic they use is exact value versus value type validation for JSON nodes. When determining which API to use, it can be helpful to **count how many exact property versus non-null assertions you have and choose the API based on which has the higher occurrence rate**.

### Mixed value exact and type validation

#### Key pattern

1. Use of combination of exact value checks and type validation.

Before
```swift
// Example event payload
let event: [String: Any] = ["timestamp": "2024-08-06T22:45:26Z", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual(123, flattenedEventData["key1"]) // (Key pattern 1.) exact value
XCTAssertNotNil(flattenedEventData["timestamp"]) // (Key pattern 1.) value type
```

After (option 1: base mode exact value validation)
```swift
let expected = """{ "timestamp": "STRING_TYPE", "key1": 123 }""" // "STRING_TYPE" is just a value convention - the only requirement is that the value type is the one you want to validate
assertExactMatch( // Base value comparison mode is exact match
    expected: expected,
    actual: event,
    pathOptions: ValueTypeMatch(paths: "timestamp")) // Enables value type validation for the specified path
```

After (option 2: base mode value type validation)
```swift
let expected = """{ "timestamp": "STRING_TYPE", "key1": 123 }""" // "STRING_TYPE" is just a value convention - the only requirement is that the value type is the one you want to validate
assertTypeMatch( // Base value comparison mode is type match
    expected: expected,
    actual: event,
    pathOptions: ValueExactMatch(paths: "key1")) // Enables exact value validation for the specified path
```

This pattern is commonly encountered when performing JSON payload validation with randomly generated or time-based values, such as ECIDs or timestamps. By using only value type validation on these values, the correct type can be validated without needing to pre-capture the actual value.

### Collection equal count

#### Key pattern

1. Use of flattened dictionary count.
2. Use of other path option logic that prevents using [`assertEquals`](#equals-validation).

Before
```swift
// Example event payload
let event: [String: Any] = ["timestamp": "2024-08-06T22:45:26Z", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual(2, flattenedEventData.count) // (Key pattern 1.)
XCTAssertEqual(123, flattenedEventData["key1"]) // (Key pattern 2.) exact value - requiring other path option
XCTAssertNotNil(flattenedEventData["timestamp"]) // (Key pattern 2.) value type - requiring other path option
```

After
```swift
let expected = """{ "timestamp": "STRING_TYPE", "key1": 123 }"""
assertExactMatch(
    expected: expected,
    actual: event,
    pathOptions: 
        CollectionEqualCount(scope: .subtree), // Disables extensible collections from the root of the JSON and all nodes under it
        ValueTypeMatch(paths: "timestamp")) // Mix of value exact and type validation prevents using `assertEqual`
```

This pattern is commonly encountered when explicitly restricting the number of actual elements to match what is expected, as the default validation logic allows for extensible collections.

### Element count validation

#### Key pattern

1. Use of flattened dictionary count without checking each property individually.

Before
```swift
// Example event payload
let event: [String: Any] = ["type": "edge", "key1": 123]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertEqual(2, flattenedEventData.count) // (Key pattern 1.) flattened dictionary count
XCTAssertEqual("edge", flattenedEventData["type"])
// (Key pattern 1.) Notice not all properties are covered in the property-by-property assertion
```

After
```swift
let expected = """{ "type": "edge" }""" // Notice only defining expected validation for property that was explicitly covered
assertExactMatch(
    expected: expected,
    actual: event,
    pathOptions: ElementCount(requiredCount: 2, scope: .subtree)) // Element count with 2 total properties in the entire JSON 
    // The combination of: 
    // 1. Default `paths` = `nil` -> root of the JSON, AND
    // 2. `scope` = `.subtree` -> this node and everything under it
```

This pattern is commonly encountered in test cases that build on top of more granular validation covered by previous test cases. An element count is used to validate whether certain JSON sub-structures are present or absent based on the logic being tested, without the need for granular validation of sub-structures already covered by previous test cases.

### Key must be absent

#### Key pattern

1. Use of null validation to confirm the absence of a key.

Before
```swift
// Example event payload
let event: [String: Any] = ["type": "edge"]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertNil(flattenedEventData["datasetId"]) // (Key pattern 1.) Null check
```

After
```swift
let expected = """{ "type": "edge" }"""
assertExactMatch(
    expected: expected,
    actual: event,
    pathOptions: KeyMustBeAbsent(paths: "datasetId"))
```

This pattern is commonly encountered when test case logic causes a key to be removed or not added to the payload. Note that this is distinct from validating a key with a null value, in which case an exact match on a null expected value can be used.

### Value not equal

#### Key pattern

1. Use of not equals validation.

Before
```swift
// Example event payload
let event: [String: Any] = ["type": "edge"]
let flattenedEventData: [String: Any] = flattenDictionary(dict: event)
XCTAssertNotEqual("core", flattenedEventData["type"]) // (Key pattern 1.) Not equal check
```

After
```swift
let expected = """{ "type": "core" }""" // Put the value you don't want the actual value to be equal to
assertExactMatch(
    expected: expected,
    actual: event,
    pathOptions: ValueNotEqual(paths: "type")) // Specify the path that should use the value not equals logic
```



