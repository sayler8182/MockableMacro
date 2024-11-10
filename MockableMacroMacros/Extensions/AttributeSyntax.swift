import SwiftSyntax

extension AttributeSyntax {
    func isAttribute(name: String) -> Bool {
        attributeName.as(IdentifierTypeSyntax.self)?.name.text == name
    }
}
