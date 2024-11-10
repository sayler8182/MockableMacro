import SwiftDiagnostics
import SwiftSyntax

enum Diagnostics {
    private static let messageID = MessageID(
        domain: "MockableMacro",
        id: "WrongDeclarationKeyword"
    )

    static func diagnose(
        declaration: DeclSyntaxProtocol
    ) -> SwiftDiagnostics.Diagnostic? {
        guard let tokens = attemptToProtocolConversion(from: declaration) else {
            return nil
        }

        return SwiftDiagnostics.Diagnostic(
            node: declaration.root,
            message: SimpleDiagnosticMessage(
                message: "@Mock only works on protocol",
                diagnosticID: messageID,
                severity: .error
            ),
            fixIts: [
                FixIt(
                    message: SimpleDiagnosticMessage(
                        message: "replace with 'protocol'",
                        diagnosticID: messageID,
                        severity: .error
                    ),
                    changes: [
                        FixIt.Change.replace(
                            oldNode: Syntax(tokens.old),
                            newNode: Syntax(tokens.new)
                        )
                    ]
                )
            ]
        )
    }

    private static func attemptToProtocolConversion(
        from declaration: DeclSyntaxProtocol
    ) -> (old: TokenSyntax, new: TokenSyntax)? {
        switch declaration {
        case let classDeclaration as ClassDeclSyntax:
            return (
                classDeclaration.classKeyword,
                classDeclaration.classKeyword.with(
                    \.tokenKind,
                     .identifier("protocol")
                )
            )
        case let actorDeclaration as ActorDeclSyntax:
            return (
                actorDeclaration.actorKeyword,
                actorDeclaration.actorKeyword.with(
                    \.tokenKind,
                     .identifier("protocol")
                )
            )
        default:
            return nil
        }
    }
}

// SOURCE: https://github.com/DougGregor/swift-macro-examples
struct SimpleDiagnosticMessage: DiagnosticMessage, Error {
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
}

extension SimpleDiagnosticMessage: FixItMessage {
    var fixItID: MessageID { diagnosticID }
}

enum CustomError: Error, CustomStringConvertible {
    case message(String)

    var description: String {
        switch self {
        case .message(let text):
            return text
        }
    }
}
