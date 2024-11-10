import Foundation
import SwiftSyntax

extension FunctionDeclSyntax {
    var stubName: String {
        var prefixName: String = name.text
        do {
            let text = description
            let pattern = #"/// @MockName\(\"(.*)\"\)"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(text.startIndex..., in: text)
            let results = regex.matches(in: text, range: range)
            let result = results
                .compactMap { result -> String? in
                    guard let range = Range(result.range(at: 1), in: text) else { return nil }
                    return String(text[range])
                }
                .first
            if let resultValue = result {
                prefixName = resultValue
            }
        } catch { /* use default name */ }
        return "\(prefixName)Stub"
    }

    var argsStubSignature: String {
        let type = signature.returnClause?.type.typeString ?? "Void"
        let parameters = signature.parameterClause.parameters
            .map { "_ \($0.name): \($0.type.typeString)" }
            .joined(separator: ", ")
        return [
            ": ((\(parameters))",
            "\(effectSpecifiersDefinition)",
            "-> \(type))"
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var argsSignature: String {
        let parameters = signature.parameterClause.parameters
            .map { "\($0.fullName): \($0.type.typeString)" }
            .joined(separator: ", ")
        let typeString = signature.returnClause?.type.typeString ?? "Void"
        return [
            "(\(parameters))",
            "\(effectSpecifiersDefinition)",
            typeString != "Void" ? "-> \(typeString)" : ""
        ]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var parametersCall: String {
        signature.parameterClause.parameters
            .map { "\($0.callReferencePrefix)\($0.name)" }
            .joined(separator: ", ")
    }

    var effectSpecifiersDefinition: String {
        var result: [String] = []
        if signature.effectSpecifiers?.asyncSpecifier != nil {
            result.append("async")
        }
        if signature.effectSpecifiers?.throwsSpecifier != nil {
            result.append("throws")
        }
        return result.joined(separator: " ")
    }

    var effectSpecifiersCall: String {
        var result: [String] = []
        if signature.effectSpecifiers?.throwsSpecifier != nil {
            result.append("try")
        }
        if signature.effectSpecifiers?.asyncSpecifier != nil {
            result.append("await")
        }
        return result.joined(separator: " ")
    }
}

extension FunctionParameterListSyntax.Element {
    var callReferencePrefix: String {
        let specifier = type.as(AttributedTypeSyntax.self)?.specifier
        if specifier?.tokenKind == .keyword(.inout) {
            return "&"
        }
        return ""
    }
    var name: String {
        secondName?.text ?? firstName.text
    }

    var fullName: String {
        [
            firstName.text,
            secondName?.text
        ]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}
