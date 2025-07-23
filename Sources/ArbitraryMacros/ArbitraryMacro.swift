import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        guard let argument = node.arguments.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

public struct ArbitraryMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
      ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw ArbitraryError.structureInvalid
        }

        let properties = structDecl.memberBlock.members.compactMap {
            member -> (String, TypeSyntax, ExprSyntax?)? in
            guard
                let varDecl = member.decl.as(VariableDeclSyntax.self),
                let binding = varDecl.bindings.first,
                let identPattern = binding.pattern.as(
                    IdentifierPatternSyntax.self
                ),
                let type = binding.typeAnnotation?.type
            else {
                return nil
            }

            // 是否包含 @ArbitraryIgnored
            let hasIgnored =
            varDecl.attributes.contains(where: {
                    $0.as(AttributeSyntax.self)?.attributeName.description
                    .trimmingCharacters(in: .whitespacesAndNewlines) == "ArbitraryIgnored"
            })

            if hasIgnored { return nil }

            let varName = identPattern.identifier.text
            let strategyAttr = varDecl.attributes.first(where: {
                $0.as(AttributeSyntax.self)?.attributeName.description.trimmingCharacters(in: .whitespacesAndNewlines)
                    == "Strategy"
            })

            let strategyExpr = strategyAttr?.as(AttributeSyntax.self)?
                .arguments?.as(LabeledExprListSyntax.self)?.first?
                .expression

            return (varName, type, strategyExpr)
        }
        
        // 构造 Gen.zip(...) 调用
       let genExprs = properties.map { name, type, strategy in
           if let strategy = strategy {
               return strategy.description
           } else {
               return "\(type.trimmed).arbitrary"
           }
       }

        let zipCall = "Gen.zip(\(genExprs.joined(separator: ", "))).map(\(structDecl.name.text).init)"

        let extensionDeclSyntax = try ExtensionDeclSyntax("""
       extension \(raw: structDecl.name.text): Arbitrary {
           public static var arbitrary: Gen<\(raw: structDecl.name.text)> {
               \(raw: zipCall)
           }
       }
       """)
        return [extensionDeclSyntax]
    }
}

public struct StrategyMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [] // 什么都不做，只是为了让语法合法
    }
}

public struct ArbitraryIgnoredMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        return [] // 同样只作为标记
    }
}

@main
struct ArbitraryMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        ArbitraryMacro.self,
        ArbitraryIgnoredMacro.self,
        StrategyMacro.self
    ]
}

public enum ArbitraryError: Error {
    case structureInvalid
}
