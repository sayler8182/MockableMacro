import SwiftSyntax

extension VariableDeclSyntax {
    var stubName: String {
        "\(name)Stub"
    }

    /// variable name
    /// example `var age: Int?` will return age
    var name: String {
        bindings.first!.pattern.as(IdentifierPatternSyntax.self)!.identifier.text
    }

    /// variable type
    /// example `var name: String` will return `String`
    var typeString: String {
        bindings.first!.typeAnnotation!.type.typeString
    }

    var isOptional: Bool {
        typeString.last == "?"
    }

    var isAnyPublisher: Bool {
        typeString.hasPrefix("AnyPublisher<")
    }

    /// SOURCE: https://github.com/DougGregor/swift-macro-examples
    /// Determine whether this variable has the syntax of a stored property.
    ///
    /// This syntactic check cannot account for semantic adjustments due to,
    /// e.g., accessor macros or property wrappers.
    var isStoredProperty: Bool {
        if bindings.count != 1 {
            return false
        }

        let binding = bindings.first!
        switch binding.accessorBlock?.accessors {
        case .none:
            return true
        case .accessors(let node):
            for accessor in node {
                // Observers can occur on a stored property.
                if case .keyword(.set) = accessor.accessorSpecifier.tokenKind {
                    return true
                }
            }

            return false

        case .getter:
            return false
        }
    }
}
