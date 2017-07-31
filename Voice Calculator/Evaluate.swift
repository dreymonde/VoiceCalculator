// Swift Playground
import Foundation

public protocol ExpressionOperation {
    
    var priority: Int { get }
    
    func evaluate(left: Double, right: Double) -> Double
    
}

public enum BasicArithmetic : ExpressionOperation, CustomStringConvertible {
    
    case addition
    case subtraction
    case multiplication
    case division
    
    public var priority: Int {
        switch self {
        case .addition, .subtraction:
            return 5
        case .multiplication, .division:
            return 10
        }
    }
    
    public var description: String {
        switch self {
        case .addition:
            return "+"
        case .subtraction:
            return "-"
        case .multiplication:
            return "×"
        case .division:
            return "/"
        }
    }
    
    public func evaluate(left: Double, right: Double) -> Double {
        switch self {
        case .addition:
            return left + right
        case .subtraction:
            return left - right
        case .multiplication:
            return left * right
        case .division:
            return left / right
        }
    }
    
}

public class Expression {
    
    public class Node {
        
        public enum Neighbor {
            case number(Double)
            case unsolved(Node)
        }
        
        var left: Neighbor
        var right: Double
        var operation: ExpressionOperation
        
        public init(left: Double, operation: ExpressionOperation, right: Double) {
            self.left = .number(left)
            self.operation = operation
            self.right = right
        }
        
        public init(left: Node, operation: ExpressionOperation, right: Double) {
            self.left = .unsolved(left)
            self.operation = operation
            self.right = right
        }
        
        public func string() -> String {
            let num: Double = {
                switch left {
                case .number(let number):
                    return number
                case .unsolved(let node):
                    return node.right
                }
            }()
            return "\(num)\(operation)\(right)"
        }
        
        public func fullString() -> String {
            var str = ""
            switch left {
            case .number(let number):
                str.append(NumberFormatter.decimal.string(from: number as NSNumber) ?? "")
            case .unsolved(let node):
                str.append(node.fullString())
            }
            let rightString = NumberFormatter.decimal.string(from: right as NSNumber) ?? ""
            str.append("\(operation)\(rightString)")
            return str
        }
        
        func evaluate() -> Neighbor {
            switch left {
            case .number(let number):
                let result = operation.evaluate(left: number, right: right)
                return .number(result)
            case .unsolved(let node):
                let result = operation.evaluate(left: node.right, right: right)
                node.right = result
                return .unsolved(node)
            }
        }
        
        func fold(highest: Node) -> (neighbor: Neighbor, isAfterEvaluatingHighest: Bool) {
            switch left {
            case .number:
                let neighbor = highest.evaluate()
                return (neighbor, isAfterEvaluatingHighest: true)
            case .unsolved(let node):
                if node.operation.priority >= highest.operation.priority {
                    let folded = node.fold(highest: node)
                    self.left = folded.neighbor
                    return (.unsolved(self), isAfterEvaluatingHighest: false)
                } else {
                    let folded = node.fold(highest: highest)
                    if folded.isAfterEvaluatingHighest {
                        return folded
                    } else {
                        self.left = folded.neighbor
                        return (.unsolved(self), isAfterEvaluatingHighest: false)
                    }
                }
            }
        }
        
        func fullFold() -> Double {
            let folded = fold(highest: self)
            switch folded.neighbor {
            case .number(let num):
                return num
            case .unsolved(let node):
                return node.fullFold()
            }
        }
        
        func evaluateAll() -> Double {
            return fullFold()
        }
        
    }
    
    public let rightmostNode: Node
    
    public init(rightmostNode: Node) {
        self.rightmostNode = rightmostNode
    }
    
    public func evaluate() -> Double {
        return rightmostNode.evaluateAll()
    }
    
}

public protocol Operatable {
    
    func node(withOperation operation: ExpressionOperation, number: Double) -> Expression.Node
    
}

extension Operatable {
    
    public func op(_ operation: BasicArithmetic, _ number: Double) -> Expression.Node {
        return node(withOperation: operation, number: number)
    }
    
}

extension Double : Operatable {
    
    public func node(withOperation operation: ExpressionOperation, number: Double) -> Expression.Node {
        return Expression.Node(left: self, operation: operation, right: number)
    }
    
}

extension Expression.Node : Operatable {
    
    public func node(withOperation operation: ExpressionOperation, number: Double) -> Expression.Node {
        return Expression.Node(left: self, operation: operation, right: number)
    }
    
    public func expression() -> Expression {
        return Expression(rightmostNode: self)
    }
    
}
