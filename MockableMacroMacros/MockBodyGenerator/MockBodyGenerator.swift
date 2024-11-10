import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct MockBodyGenerator {
    fileprivate enum Error: Swift.Error {
        case missingDeclarationName
    }

    private let config: MockMacroArgs.Config

    init(config: MockMacroArgs.Config) {
        self.config = config
    }

    func generateBody(from declaration: ProtocolDeclSyntax) throws -> [DeclSyntax] {
        guard let memberName = declaration.name else {
            throw Error.missingDeclarationName
        }

        let accessControlModifier = declaration.accessControlModifier
            .flatMap { "\($0.name.text)" } ?? ""
        let variables = declaration.variables
        let methods = declaration.methods

        return generateBody(
            accessControlModifier: accessControlModifier,
            memberName: memberName,
            variables: variables,
            methods: methods
        )
    }
}

// MARK: Body Generation
extension MockBodyGenerator {
    fileprivate func generateBody(
        accessControlModifier: String,
        memberName: String,
        variables: [VariableDeclSyntax],
        methods: [FunctionDeclSyntax]
    ) -> [DeclSyntax] {
        let syntax = [
            "\(startDebugDecl())",
            "\(startMockDecl(accessControlModifier: accessControlModifier, memberName: memberName))",
            "\(variablesStub(accessControlModifier: accessControlModifier, variables: variables))",
            "\(methodsStub(accessControlModifier: accessControlModifier, methods: methods))",
            "\(variablesDefinition(accessControlModifier: accessControlModifier, variables: variables))",
            "\(initDefinition(accessControlModifier: accessControlModifier))",
            "\(methodsDefinition(accessControlModifier: accessControlModifier, methods: methods))",
            "\(stopMockDecl())",
            "\(stopDebugDecl())"
        ]
        let result = syntax
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        return ["\(raw: result)"]
    }

    private func startDebugDecl() -> String {
        return """
        #if DEBUG
        """
    }

    private func startMockDecl(accessControlModifier: String,
                               memberName: String) -> String {
        [
            "\(accessControlModifier)",
            "final class \(memberName)Mock: \(memberName), @unchecked Sendable {"
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func variablesStub(accessControlModifier: String,
                               variables: [VariableDeclSyntax]) -> String {
        variables
            .map {
                variableStub(
                    accessControlModifier: accessControlModifier,
                    variable: $0,
                    isUnimplemented: config.isUnimplemented)
            }
            .joined(separator: "\n")
    }

    private func methodsStub(accessControlModifier: String,
                             methods: [FunctionDeclSyntax]) -> String {
        methods
            .map {
                methodStub(
                    accessControlModifier: accessControlModifier,
                    method: $0,
                    isUnimplemented: config.isUnimplemented)
            }
            .joined(separator: "\n")
    }

    private func variablesDefinition(accessControlModifier: String,
                                     variables: [VariableDeclSyntax]) -> String {
        variables
            .map { variableDefinition(accessControlModifier: accessControlModifier, variable: $0) }
            .joined(separator: "\n")
    }

    private func initDefinition(accessControlModifier: String) -> String {
        if accessControlModifier == "public" || accessControlModifier == "open" {
            return "\(accessControlModifier) init() { }"
        }
        return ""
    }

    private func methodsDefinition(accessControlModifier: String,
                                   methods: [FunctionDeclSyntax]) -> String {
        methods
            .map { methodDefinition(accessControlModifier: accessControlModifier, method: $0) }
            .joined(separator: "\n")
    }

    private func stopMockDecl() -> String {
        "}"
    }

    private func stopDebugDecl() -> String {
        return """
        #endif
        """
    }
}

// MARK: Utils
extension MockBodyGenerator {
    func variableStub(accessControlModifier: String,
                      variable: VariableDeclSyntax,
                      isUnimplemented: Bool) -> String {
        if !variable.isStoredProperty && variable.isAnyPublisher {
            /// combine property eg `var variable: AnyPublisher<Void, Never> { get }`
            let type = variable.typeString
                .replacingOccurrences(of: "AnyPublisher", with: "PassthroughSubject")
            return [
                "\(accessControlModifier)",
                "let \(variable.name)Subject: \(type) = .init()"
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else if variable.isStoredProperty {
            /// stored property eg `var variable: String { get set }`
            let type = variable.isOptional
            ? variable.typeString
            : "\(variable.typeString)!"
            return [
                "\(accessControlModifier)",
                "var \(variable.stubName): \(type)"
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else {
            /// computed property eg `var variable: String { get }`
            let lazyModifier = isUnimplemented ? "lazy" : ""
            let definition = isUnimplemented ? " = { XCTUnimplemented.handle() }()" : "!"
            return [
                "\(accessControlModifier)",
                "\(lazyModifier)",
                "var \(variable.stubName): (() -> \(variable.typeString))\(definition)"
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }

    private func methodStub(accessControlModifier: String,
                            method: FunctionDeclSyntax,
                            isUnimplemented: Bool) -> String {
        let lazyModifier = isUnimplemented ? "lazy" : ""
        let definition = isUnimplemented ? " = { XCTUnimplemented.handle() }()" : "!"
        return [
            "\(accessControlModifier)",
            "\(lazyModifier)",
            "var \(method.stubName)\(method.argsStubSignature)\(definition)"
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func variableDefinition(accessControlModifier: String,
                                    variable: VariableDeclSyntax) -> String {
        if !variable.isStoredProperty && variable.isAnyPublisher {
            /// combine property eg `var variable: AnyPublisher<Void, Never> { get }`
            return [
                "\(accessControlModifier)",
                """
                var \(variable.name): \(variable.typeString) {
                    \(variable.name)Subject.eraseToAnyPublisher()
                }
                """
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else if variable.isStoredProperty {
            /// stored property eg `var variable: String { get set }`
            return [
                "\(accessControlModifier)",
                """
                var \(variable.name): \(variable.typeString) {
                    get { \(variable.stubName) }
                    set { \(variable.stubName) = newValue }
                }
                """
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        } else {
            /// computed property eg `var variable: String { get }`
            return [
                "\(accessControlModifier)",
                """
                var \(variable.name): \(variable.typeString) {
                    \(variable.stubName)()
                }
                """
            ]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }
    }
    
    private func methodDefinition(accessControlModifier: String,
                                  method: FunctionDeclSyntax) -> String {
        return [
            "\(accessControlModifier)",
            [
                "func \(method.name.text)\(method.argsSignature) {",
                [
                    "\(method.effectSpecifiersCall)",
                    "\(method.stubName)(\(method.parametersCall))"
                ]
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                ,
                "}"
            ]
                .joined(separator: "\n")
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
