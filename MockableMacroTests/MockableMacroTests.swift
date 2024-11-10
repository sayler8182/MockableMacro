// swiftlint:disable all
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

#if canImport(MockableMacroMacros)
import MockableMacroMacros

import SwiftSyntax
import SwiftParser

let testMacros: [String: Macro.Type] = [
    "Mock": MockMacro.self
]

final class MockableMacroTests: XCTestCase {
    func testMacroVariableComputedNullable() throws {
        assertMacroExpansion(
            """
            @Mock
            public protocol Service {
                public var variable: String? { get }
            }
            """,
            expandedSource: """
            public protocol Service {
                public var variable: String? { get }
            }

            #if DEBUG
            public final class ServiceMock: Service, @unchecked Sendable {
                public lazy var variableStub: (() -> String?) = {
                    XCTUnimplemented.handle()
                }()
                public var variable: String? {
                    variableStub()
                }
                public init() {
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroVariableComputed() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                var variable: String { get }
            }
            """,
            expandedSource: """
            protocol Service {
                var variable: String { get }
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var variableStub: (() -> String) = {
                    XCTUnimplemented.handle()
                }()
                var variable: String {
                    variableStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroVariableStoredNullable() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                var variable: String? { get set }
            }
            """,
            expandedSource: """
            protocol Service {
                var variable: String? { get set }
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                var variableStub: String?
                var variable: String? {
                    get {
                        variableStub
                    }
                    set {
                        variableStub = newValue
                    }
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroVariableStored() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                var variable: String { get set }
            }
            """,
            expandedSource: """
            protocol Service {
                var variable: String { get set }
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                var variableStub: String!
                var variable: String {
                    get {
                        variableStub
                    }
                    set {
                        variableStub = newValue
                    }
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodVoid() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method() async throws
            }
            """,
            expandedSource: """
            protocol Service {
                func method() async throws
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: (() async throws -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method() async throws {
                    try await methodStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodString() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method() async -> String
            }
            """,
            expandedSource: """
            protocol Service {
                func method() async -> String
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: (() async -> String) = {
                    XCTUnimplemented.handle()
                }()
                func method() async -> String {
                    await methodStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodIntOptional() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method() async -> Int?
            }
            """,
            expandedSource: """
            protocol Service {
                func method() async -> Int?
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: (() async -> Int?) = {
                    XCTUnimplemented.handle()
                }()
                func method() async -> Int? {
                    await methodStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodNamedParameter() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(p1: String?) async -> Int?
            }
            """,
            expandedSource: """
            protocol Service {
                func method(p1: String?) async -> Int?
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ p1: String?) async -> Int?) = {
                    XCTUnimplemented.handle()
                }()
                func method(p1: String?) async -> Int? {
                    await methodStub(p1)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodNamedParameters() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(p1: String?, p2: Int) async -> Int?
            }
            """,
            expandedSource: """
            protocol Service {
                func method(p1: String?, p2: Int) async -> Int?
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ p1: String?, _ p2: Int) async -> Int?) = {
                    XCTUnimplemented.handle()
                }()
                func method(p1: String?, p2: Int) async -> Int? {
                    await methodStub(p1, p2)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodAnonymousParameters() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(_ p1: String?, p2: Int) async -> Int?
            }
            """,
            expandedSource: """
            protocol Service {
                func method(_ p1: String?, p2: Int) async -> Int?
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ p1: String?, _ p2: Int) async -> Int?) = {
                    XCTUnimplemented.handle()
                }()
                func method(_ p1: String?, p2: Int) async -> Int? {
                    await methodStub(p1, p2)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodClosure() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(onSuccess: () -> Void) async
            }
            """,
            expandedSource: """
            protocol Service {
                func method(onSuccess: () -> Void) async
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ onSuccess: () -> Void) async -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method(onSuccess: () -> Void) async {
                    await methodStub(onSuccess)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodClosureEscaping() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(onSuccess: @escaping () -> Void) async
            }
            """,
            expandedSource: """
            protocol Service {
                func method(onSuccess: @escaping () -> Void) async
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ onSuccess: @escaping () -> Void) async -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method(onSuccess: @escaping () -> Void) async {
                    await methodStub(onSuccess)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodClosureEscapingMainActor() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(onSuccess: @escaping @MainActor () -> Void) async
            }
            """,
            expandedSource: """
            protocol Service {
                func method(onSuccess: @escaping @MainActor () -> Void) async
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ onSuccess: @escaping @MainActor () -> Void) async -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method(onSuccess: @escaping @MainActor () -> Void) async {
                    await methodStub(onSuccess)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodClosureEscapingMainActorWithNamedParameters() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(onSuccess: @escaping @MainActor (_ p1: Int) -> Void) async
            }
            """,
            expandedSource: """
            protocol Service {
                func method(onSuccess: @escaping @MainActor (_ p1: Int) -> Void) async
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ onSuccess: @escaping @MainActor (_ p1: Int) -> Void) async -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method(onSuccess: @escaping @MainActor (_ p1: Int) -> Void) async {
                    await methodStub(onSuccess)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroMethodClosureEscapingMainActorWithAnonymousParameters() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(onSuccess: @escaping @MainActor (Int) -> Float) async throws -> String
            }
            """,
            expandedSource: """
            protocol Service {
                func method(onSuccess: @escaping @MainActor (Int) -> Float) async throws -> String
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ onSuccess: @escaping @MainActor (Int) -> Float) async throws -> String) = {
                    XCTUnimplemented.handle()
                }()
                func method(onSuccess: @escaping @MainActor (Int) -> Float) async throws -> String {
                    try await methodStub(onSuccess)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroCustomName() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                /// @MockName("customName")
                func method() async throws
            }
            """,
            expandedSource: """
            protocol Service {
                /// @MockName("customName")
                func method() async throws
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var customNameStub: (() async throws -> Void) = {
                    XCTUnimplemented.handle()
                }()
                func method() async throws {
                    try await customNameStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroUnimplemented() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service: Sendable {
                var variable: String { get set }
                var getter: String { get }
                func method() async throws -> Int
            }
            """,
            expandedSource: """
            protocol Service: Sendable {
                var variable: String { get set }
                var getter: String { get }
                func method() async throws -> Int
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                var variableStub: String!
                lazy var getterStub: (() -> String) = {
                    XCTUnimplemented.handle()
                }()
                lazy var methodStub: (() async throws -> Int) = {
                    XCTUnimplemented.handle()
                }()
                var variable: String {
                    get {
                        variableStub
                    }
                    set {
                        variableStub = newValue
                    }
                }
                var getter: String {
                    getterStub()
                }
                func method() async throws -> Int {
                    try await methodStub()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroInout() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service {
                func method(param: inout Int) -> Int
            }
            """,
            expandedSource: """
            protocol Service {
                func method(param: inout Int) -> Int
            }
            
            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                lazy var methodStub: ((_ param: inout Int) -> Int) = {
                    XCTUnimplemented.handle()
                }()
                func method(param: inout Int) -> Int {
                    methodStub(&param)
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }

    func testMacroCombine() throws {
        assertMacroExpansion(
            """
            @Mock
            protocol Service: Sendable {
                var subscriptionsChanged: AnyPublisher<Int, Never> { get }
            }
            """,
            expandedSource: """
            protocol Service: Sendable {
                var subscriptionsChanged: AnyPublisher<Int, Never> { get }
            }

            #if DEBUG
            final class ServiceMock: Service, @unchecked Sendable {
                let subscriptionsChangedSubject: PassthroughSubject<Int, Never> = .init()
                var subscriptionsChanged: AnyPublisher<Int, Never> {
                    subscriptionsChangedSubject.eraseToAnyPublisher()
                }
            }
            #endif
            """,
            macros: testMacros
        )
    }
}
#endif
// swiftlint:enable all
