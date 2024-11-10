import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MockMacro: PeerMacro {
    enum Error: Swift.Error, CustomStringConvertible {
        case missingArgument(String)
        case incorrectOptionsArgument
        case incorrectDefaultValuesArgument(String)
        case wrongDeclarationSyntax

        var description: String {
            switch self {
            case .missingArgument(let name):
                return "'\(name)' argument is missing"
            case .incorrectOptionsArgument:
                return "Options argument is incorrect"
            case .incorrectDefaultValuesArgument(let name):
                return "'\(name)' argument is missing"
            case .wrongDeclarationSyntax:
                return "Mock Macro supports only protocol"
            }
        }
    }

    public static func expansion<
        Declaration: DeclSyntaxProtocol, Context: MacroExpansionContext
    >(
        of node: AttributeSyntax,
        providingPeersOf declaration: Declaration,
        in context: Context
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ProtocolDeclSyntax.self) else {
            guard let diagnostic = Diagnostics.diagnose(declaration: declaration) else {
                throw MockMacro.Error.wrongDeclarationSyntax
            }

            context.diagnose(diagnostic)
            return []
        }

        let config = try MockMacroArgs.Config(from: node, isUnimplemented: true)

        let bodyGenerator = MockBodyGenerator(config: config)
        return try bodyGenerator.generateBody(from: declaration)
    }
}
