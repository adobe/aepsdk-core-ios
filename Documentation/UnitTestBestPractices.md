# Unit Test Best Practices

## First principles
- Fast
- Isolated/Independent
- Repeatable
- Self-validating
- Thorough

## Mock via Protocols
- Use protocols for all dependencies when possible in order to allow us to more easily create mocks
- Even if we are using protocols only for the sake of testability that is a good enough reason

## Dependency Injection
- Use dependency injection in order to more easily inject mocks 
- AEP Services are the exception as we use the service provider to set our mocks instead

## XCTAssert
- Do not only use XCTAssert with a complex boolean statement when asserting but make use of `XCTAssertNil`, `XCTAssertFalse`, `XCTAssertEqual`, etc. 
- To test asynchronous code use `XCTestExpectation`: https://developer.apple.com/documentation/xctest/xctestexpectation

## Clarity
- Add a doc comment for each test case describing in English what the test case is testing
- When necessary, include log messages which clarify failures in your assertions
