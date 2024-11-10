import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum MockMacroArgs {
    struct Config {
        let isUnimplemented: Bool

        init(isUnimplemented: Bool) {
            self.isUnimplemented = isUnimplemented
        }
        
        init(from node: AttributeSyntax,
             isUnimplemented: Bool) throws {
            self.init(isUnimplemented: isUnimplemented)
        }
    }
}
