//
//  WeakReference.swift
//  CoronaMath
//
//  Created by Cooper Knaak on 1/10/19.
//

import Foundation

///A wrapper for a class object that maintains a weak reference to the object.
///For example, useful for storing weak references in an array.
public class WeakReference<T: AnyObject>: Hashable {


    ///The object to be wrapped.
    public private(set) weak var object:T? = nil

    ///Initializes a `WeakReference` instance by wrapping the given object.
    ///- parameter object: The object to wrap in a weak reference.
    public init(object:T?) {
        self.object = object
    }

    public func hash(into hasher: inout Hasher) {
        if let obj = object {
            hasher.combine(Unmanaged.passUnretained(obj).toOpaque())
        }
    }

}

public func ==<T>(lhs: WeakReference<T>, rhs: WeakReference<T>) -> Bool where T: AnyObject {
    if lhs.object == nil && rhs.object == nil {
        return true
    }
    guard let leftObject = lhs.object, let rightObject = rhs.object else {
        return false
    }
    return leftObject === rightObject
}
