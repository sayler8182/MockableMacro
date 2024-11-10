import MockableMacro

@Mock
protocol Service {
    var valueGet: String { get }
    var valueGetAndSet: [Int] { get set }

    func methodVoid() async throws
    func methodVoidWithParameters(param1: String) async throws
    func methodVoidWithParametersReturns(param1: String) async throws -> Int
}

@Mock
protocol ServiceDuplicates {
    /// @MockName("methodAsync")
    func method() async throws
    /// @MockName("methodClosure")
    func method(onSuccess: (Result<Void, Error>) -> Void)
}

// unimplemented requires XCTUnimplemented definition
enum XCTUnimplemented {
    static func handle() -> Never { fatalError("Fatal") }
}

@Mock
protocol ServiceUnimplemented: Sendable {
    var variable: String { get set }
    var getter: String { get }
    func method() async throws -> Int
}
