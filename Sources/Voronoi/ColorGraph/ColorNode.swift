//
//  ColorNode.swift
//  CoronaErrors
//
//  Created by Cooper Knaak on 1/30/19.
//

import Foundation

///Wraps an instance of type `T` and stores its corresponding `color` value.
internal class ColorNode<T: Hashable>: Hashable {
    ///The wrapped value.
    internal let value:T
    ///The value of this node's `color`.
    internal var color:Int = -1

    internal var hashValue: Int {
        return self.value.hashValue
    }

    internal init(value:T) {
        self.value = value
    }
}

internal func ==<T>(lhs:ColorNode<T>, rhs:ColorNode<T>) -> Bool {
    return lhs.value == rhs.value
}
