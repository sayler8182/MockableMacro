import SwiftSyntax

extension ProtocolDeclSyntax {
    /// Declaration name
    /// example: struct User will return "User"
    var name: String? {
        asProtocol(NamedDeclSyntax.self)?.name.text
    }

    var accessControlModifier: DeclModifierSyntax? {
        modifiers.first(where: {
            let tokenKind = $0.name.tokenKind
            return tokenKind == .keyword(.fileprivate)
            || tokenKind == .keyword(.private)
            || tokenKind == .keyword(.internal)
            || tokenKind == .keyword(.public)
        })
    }

    var variables: [VariableDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
    }

    var methods: [FunctionDeclSyntax] {
        memberBlock.members
            .compactMap { $0.decl.as(FunctionDeclSyntax.self) }
    }

    func isInherite(type: String) -> Bool {
        inheritanceClause?.inheritedTypes
            .contains(where: { $0.type.typeString == type }) ?? false
    }
}
