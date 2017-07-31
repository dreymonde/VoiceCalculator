//
//  ThreadSafe.swift
//  Voice Calculator
//
//  Created by Олег on 31.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import Foundation

public struct ThreadSafe<Value> {
    
    private var _value: Value
    private let queue = DispatchQueue(label: "thread-safety-queue", attributes: [.concurrent])
    
    public init(_ value: Value) {
        self._value = value
    }
    
    public func read() -> Value {
        return queue.sync { _value }
    }
    
    public mutating func write(_ modify: (inout Value) -> ()) {
        queue.sync(flags: .barrier) {
            modify(&_value)
        }
    }
    
    public mutating func write(_ newValue: Value) {
        queue.sync(flags: .barrier) {
            _value = newValue
        }
    }
    
}
