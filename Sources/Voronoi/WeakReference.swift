//
//  WeakReference.swift
//  CoronaMath
//
//  Created by Cooper Knaak on 1/10/19.
//

import Foundation

///A wrapper for a class object that maintains a weak reference to the object.
///For example, useful for storing weak references in an array.
public class WeakReference<T: AnyObject> {

    ///The object to be wrapped.
    public private(set) weak var object:T? = nil

    ///Initializes a `WeakReference` instance by wrapping the given object.
    ///- parameter object: The object to wrap in a weak reference.
    public init(object:T?) {
        self.object = object
    }

}
