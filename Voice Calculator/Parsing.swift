//
//  Processing.swift
//  Evaluate
//
//  Created by Олег on 23.07.17.
//
//

import Foundation

extension Expression {
    
    public enum Token {
        case number(Double)
        case operation(ExpressionOperation)
    }
    
}

extension BasicArithmetic {
    
    public static var parser: ExpressionTokenParser {
        return ExpressionTokenParser(elementOfTag: { (element, tag) -> Expression.Token? in
            switch element {
            case "-", "minus", "subtracting":
                return .operation(BasicArithmetic.subtraction)
            case "+", "plus", "adding", "add":
                return .operation(BasicArithmetic.addition)
            case "*", "×", "times":
                return .operation(BasicArithmetic.multiplication)
            case "/", "divided", "÷":
                return .operation(BasicArithmetic.division)
            default:
                return nil
            }
        })
    }
    
}

extension NumberFormatter {
    
    public static let spellOut: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .spellOut
        return nf
    }()
    
    public static let decimal: NumberFormatter = {
        let nf = NumberFormatter()
        nf.locale = Locale(identifier: "en_US")
        nf.numberStyle = .decimal
        return nf
    }()

    public static let expressionTokenParser: ExpressionTokenParser = ExpressionTokenParser { (element, tag) -> Expression.Token? in
        if let decimal = NumberFormatter.decimal.number(from: element) as? Double {
            return .number(decimal)
        }
        if let spellOut  = NumberFormatter.spellOut.number(from: element) as? Double {
            return .number(spellOut)
        }
        return nil
    }
    
}

public struct ExpressionTokenParser {
    
    private let _parse: (String, String) -> Expression.Token?
    
    public init(elementOfTag: @escaping (String, String) -> Expression.Token?) {
        self._parse = elementOfTag
    }
    
    public func parse(element: String, of tag: String) -> Expression.Token? {
        return _parse(element, tag)
    }
    
    public static let always0 = ExpressionTokenParser(elementOfTag: { _ in .number(0) })
    
    public func chained(with anotherParser: ExpressionTokenParser) -> ExpressionTokenParser {
        return ExpressionTokenParser(elementOfTag: { (element, tag) -> Expression.Token? in
            if let first = self.parse(element: element, of: tag) {
                return first
            } else {
                return anotherParser.parse(element: element, of: tag)
            }
        })
    }
    
}

public struct ExpressionTokensProcessor {
    
    private let _process: ([Expression.Token]) -> [Expression.Token]
    
    public init(process: @escaping ([Expression.Token]) -> [Expression.Token]) {
        self._process = process
    }
    
    public func process(tokens: [Expression.Token]) -> [Expression.Token] {
        return _process(tokens)
    }
    
    public func chained(with anotherProcessor: ExpressionTokensProcessor) -> ExpressionTokensProcessor {
        return ExpressionTokensProcessor(process: { (tokens) -> [Expression.Token] in
            let firstRound = self.process(tokens: tokens)
            return anotherProcessor.process(tokens: firstRound)
        })
    }
    
    public static var noProcessing: ExpressionTokensProcessor {
        return ExpressionTokensProcessor(process: { $0 })
    }
    
    public static var collapsingNumbers: ExpressionTokensProcessor {
        return ExpressionTokensProcessor(process: { (tokens) -> [Expression.Token] in
            var new: [Expression.Token] = []
            var previousNumber: Double?
            for token in tokens {
                switch token {
                case .number(let num):
                    previousNumber = (previousNumber ?? 0) + num
                case .operation:
                    if let previousNumber = previousNumber {
                        new.append(.number(previousNumber))
                    }
                    previousNumber = nil
                    new.append(token)
                }
            }
            if let previousNumber = previousNumber {
                new.append(.number(previousNumber))
            }
            print(new)
            return new
        })
    }
    
}

public struct UnparsedExpression {
    
    public init(_ unparsedString: String) {
        self.unparsedString = unparsedString.lowercased()
    }
    
    public let unparsedString: String
    
    public func parse(parser: ExpressionTokenParser, processor: ExpressionTokensProcessor) -> [Expression.Token] {
        var tokens: [Expression.Token] = []
        let fullRange = unparsedString.startIndex ..< unparsedString.endIndex
        unparsedString.enumerateLinguisticTags(in: fullRange, scheme: NSLinguisticTagSchemeLexicalClass) { (tag, range, _, _) in
            let pretoken = unparsedString.substring(with: range)
            if let token = parser.parse(element: pretoken, of: tag) {
                tokens.append(token)
            }
        }
        return processor.process(tokens: tokens)
    }
    
}

extension Expression {
    
    public enum Error : Swift.Error, LocalizedError {
        case firstTokenIsNotANumber(Expression.Token)
        case noTokens
        case notOperation(Token)
        case notANumber(Token)
        case evenNumberOfTokens
        case noOperations
        
        public var errorDescription: String? {
            switch self {
            case .firstTokenIsNotANumber:
                return "The expression should start with a number"
            case .noTokens, .evenNumberOfTokens, .noOperations:
                return "Invalid expression"
            case .notOperation, .notANumber:
                return "Invalid order"
            }
        }
    }
    
    public convenience init(tokens: [Expression.Token]) throws {
        guard !tokens.isEmpty else {
            throw Error.noTokens
        }
        var tokens = tokens
        let firstToken = tokens.removeFirst()
        guard case .number(let num) = firstToken else {
            throw Error.firstTokenIsNotANumber(firstToken)
        }
        let others = try Expression.split(tokens: tokens)
        var current: Operatable = num
        for (operation, number) in others {
            let next = current.node(withOperation: operation, number: number)
            current = next
        }
        guard let node = current as? Expression.Node else {
            throw Error.noOperations
        }
        self.init(rightmostNode: node)
    }
    
    static func split(tokens: [Expression.Token]) throws -> [(ExpressionOperation, Double)] {
        var tokens = tokens
        var count = tokens.count
        guard count % 2 == 0 else {
            throw Error.evenNumberOfTokens
        }
        var result: [(ExpressionOperation, Double)] = []
        while count >= 2 {
            let first = tokens.removeFirst()
            let second = tokens.removeFirst()
            count -= 2
            
            var operation: ExpressionOperation
            var number: Double
            
            if case .operation(let op) = first {
                operation = op
            } else {
                throw Error.notOperation(first)
            }
            if case .number(let num) = second {
                number = num
            } else {
                throw Error.notANumber(second)
            }
            result.append((operation, number))
        }
        return result
    }
    
}

extension Expression {
    
    public convenience init(from string: String,
                            parser: ExpressionTokenParser = NumberFormatter.expressionTokenParser.chained(with: BasicArithmetic.parser),
                            processor: ExpressionTokensProcessor = ExpressionTokensProcessor.collapsingNumbers) throws {
        let tokens = UnparsedExpression(string).parse(parser: parser, processor: processor)
        try self.init(tokens: tokens)
    }
    
}
