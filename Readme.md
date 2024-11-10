# MockableMacro

`MockableMacro` is a Swift macro library designed to make it easier to generate mock implementations of protocols for unit testing in iOS projects. With `MockableMacro`, you can quickly create mock classes that conform to your protocols, allowing you to simplify the setup of your tests, especially when dealing with complex protocols or asynchronous functions.

## Features

- Automatically generates mock classes for protocols with annotated `@Mock` macros.
- Supports async methods, closure-based methods, and custom method naming for stubs.
- Generates mocks conditionally in `DEBUG` mode, ensuring production builds remain unaffected.
- Compatible with Swift's concurrency model and supports `Sendable` protocols.
- Calls `XCTUnimplemented.handle()` in case of missing implementation

## Installation

Add `MockableMacro` to your project using Swift Package Manager. To add this package:

1. Open Xcode, select your project, and go to **File > Add Packages...**
2. Enter the repository URL for `MockableMacro` and follow the prompts to complete the installation.

## Usage

To use `MockableMacro` in your project, simply annotate your protocol with `@Mock`. Optionally, you can specify custom mock method names with `@MockName` annotations. `MockableMacro` will generate a mock class for the protocol when compiled in `DEBUG` mode.

### Example

Define your protocol and mark it with `@Mock`:

```swift
@Mock
protocol ServiceDuplicates {
    /// @MockName("methodAsync")
    func method() async throws
    /// @MockName("methodClosure")
    func method(onSuccess: (Result<Void, Error>) -> Void)
}
```

The above code will generate the following mock class automatically:

```swift
import XCTest
@testable import YourProject

class ServiceDuplicatesTests: XCTestCase {
    func testAsyncMethod() async throws {
        let mock = ServiceDuplicatesMock()

        // Define the expected behavior of the async method stub
        mock.methodAsyncStub = {
            // custom behavior for test
        }

        try await mock.method()

        // Add your assertions here
    }

    func testMethodWithClosure() {
        let mock = ServiceDuplicatesMock()

        // Define behavior for the closure method stub
        mock.methodClosureStub = { onSuccess in
            onSuccess(.success(()))
        }

        var result: Result<Void, Error>?
        mock.method { res in
            result = res
        }

        // Validate that the result was successful
        XCTAssertEqual(result, .success(()))
    }
}
```

### Usage in Tests

Once your mock is generated, you can use it in your unit tests to stub behaviors, track function calls, and verify interactions:

```swift
import XCTest
@testable import YourProject

class ServiceDuplicatesTests: XCTestCase {
    func testAsyncMethod() async throws {
        let mock = ServiceDuplicatesMock()

        // Define the expected behavior of the async method stub
        mock.methodAsyncStub = {
            // custom behavior for test
        }

        try await mock.method()

        // Add your assertions here
    }

    func testMethodWithClosure() {
        let mock = ServiceDuplicatesMock()

        // Define behavior for the closure method stub
        mock.methodClosureStub = { onSuccess in
            onSuccess(.success(()))
        }

        var result: Result<Void, Error>?
        mock.method { res in
            result = res
        }

        // Validate that the result was successful
        XCTAssertEqual(result, .success(()))
    }
}
```

## Macro Attributes

- `@Mock` - Place this above the protocol to indicate that a mock class should be generated.
- `@MockName` - (Optional) Place this above a function to provide a custom name for the generated stub method.

## Notes

MockableMacro generates mock classes only in DEBUG mode to avoid inflating the production binary.
Use @unchecked Sendable if you need to use the generated mock in a concurrent context but want to skip Sendable verification for the mock class.

## Unimplemented Method Handling

`MockableMacro` uses `XCTUnimplementedOverlay` to handle unimplemented stubs. This provides immediate feedback in tests if a stubbed method is called without a defined behavior. To set up handling for unimplemented methods, add the following extension to your `XCTestCase` subclass:

```swift
import XCTUnimplementedOverlay
import XCTest

extension XCTestCase {
    func setupUnimplementedMocks() {
        continueAfterFailure = false
        XCTUnimplemented.handler = { function, file, line in
            XCTFail("Unimplemented method: \(function)", file: file, line: line)
            Task {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                fatalError("Unimplemented", file: file, line: line)
            }
            while true { }
        }
    }
}
```

### Usage in Tests

Call setupUnimplementedMocks() in your test's setUp method to activate the handler for unimplemented mocks. This setup ensures that any unhandled calls to stubbed methods will cause the test to fail immediately, helping you identify missing implementations in your mocks.

```swift
class ServiceDuplicatesTests: XCTestCase {
    override func setUp() {
        super.setUp()
        setupUnimplementedMocks()
    }
}
```

This configuration will:

- Trigger an XCTFail when an unimplemented method is called.
- Halt the test and display an error message, aiding in pinpointing unhandled mock methods.