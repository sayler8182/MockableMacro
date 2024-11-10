// The Swift Programming Language
// https://docs.swift.org/swift-book

public enum XCTUnimplemented {
    public static var handler: ((StaticString, StaticString, UInt) -> Never)!

    public static func handle(
        function: StaticString = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Never {
        handler(function, file, line)
    }
}
