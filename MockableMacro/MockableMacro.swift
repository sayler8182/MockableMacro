// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// A macro that produces Mock
@attached(peer, names: suffixed(Mock))
public macro Mock(
    config: MockableMacroArgs.Config = .init()
) = #externalMacro(
    module: "MockableMacroMacros",
    type: "MockMacro"
)
