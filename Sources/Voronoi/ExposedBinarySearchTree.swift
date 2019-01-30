//
//  ExposedBinarySearchTree.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/9/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

public protocol ExposedBinarySearchTreeProtocol: class, Comparable {
    
    var left:Self? { get set }
    var right:Self? { get set }
    var parent:Self? { get set }
    
}

extension ExposedBinarySearchTreeProtocol {
    
    var isLeaf:Bool { return self.left == nil && self.right == nil }
    
    var hasLeftChild:Bool {
        return self.left != nil
    }
    var hasRightChild:Bool {
        return self.right != nil
    }
    var isLeftChild:Bool {
        if let left = self.parent?.left {
            return self === left
        } else {
            return false
        }
    }
    var isRightChild:Bool {
        if let right = self.parent?.right {
            return self === right
        } else {
            return false
        }
    }
    
    /**
     Gets the nearest left child of this node.
     - returns: The child with the greatest value that is still less than this node.
    */
    public func getNearestLeftChild() -> Self? {
        var child = self.left
        while let node = child , !node.isLeaf {
            child = node.right
        }
        return child
    }
    
    /**
     Gets the nearest right child of this node.
     - returns: The child with the least value that is still greater than this node.
     */
    public func getNearestRightChild() -> Self? {
        var child = self.right
        while let node = child , !node.isLeaf {
            child = node.left
        }
        return child
    }

    /**
     Gets the leftmost parent -- in which the returned parent, when recursively
     accessing the left child, will eventually result in this node.
     - returns: The superparent that has this node entirely on the left.
     */
    public func getLeftmostParent() -> Self? {
        var par = self.parent
        
        guard par != nil else {
            return nil
        }
        
        var cur:Self? = self
        while let left = par?.left , left === cur {
            cur = par
            par = par?.parent
            /*if par == nil {
                return nil
            }*/
        }
        return par
    }
    
    /**
     Gets the rightmost parent -- in which the returned parent, when recursively
     accessing the right child, will eventually result in this node.
     - returns: The superparent that has this node entirely on the right.
     */
    public func getRightmostParent() -> Self? {
        var par = self.parent
        guard par != nil else {
            return nil
        }
        var cur:Self? = self
        while let right = par?.right , right === cur {
            cur = par
            par = par?.parent
            /*if par == nil {
                return nil
            }*/
        }
        return par
    }
    
    public func iterateChildren(_ handler:(Self) -> Void) {
        handler(self)
        self.left?.iterateChildren(handler)
        self.right?.iterateChildren(handler)
    }

}

/**
 ExposedBinarySearchTree is a Binary Search Tree implementation that forces the user
 to handle the internals of adding and removing nodes. It allows the user direct access
 to the nodes rather than just the underlying elements. Users are responsible for making
 sure the structure of the tree remains intact.
 */
public struct ExposedBinarySearchTree<T: ExposedBinarySearchTreeProtocol>: CustomStringConvertible {
    
    public fileprivate(set) var root:T? = nil
    public var description:String {
        if let root = self.root {
            return ExposedBinarySearchTree.toString(root, depth: 0)
        } else {
            return "No root"
        }
    }
    public var count:Int {
        return self.calculateCountOf(self.root, leaves: false)
    }
    public var leafCount:Int {
        return self.calculateCountOf(self.root, leaves: true)
    }
    public var layers:Int {
        return self.calculateLayersOf(self.root)
    }
    
    public mutating func insert(_ value:T) {
        guard var current = self.root else {
            self.root = value
            return
        }
        
        while true {
            if value < current {
                if let left = current.left {
                    current = left
                } else {
                    current.left = value
                    value.parent = current
                    break
                }
            } else if value > current {
                if let right = current.right {
                    current = right
                } else {
                    current.right = value
                    value.parent = current
                    break
                }
            } else {
                break
            }
        }
    }
    
    public func find(_ requireLeaf:Bool, predicate:(T) -> Int) -> T? {
        var current = self.root
        while let cur = current {
            let delta = predicate(cur)
            if delta < 0 {
                current = cur.right
            } else if delta > 0 {
                current = cur.left
            } else {
                if cur.left == nil && cur.right == nil && requireLeaf {
                    return cur
                } else {
                    return nil
                }
            }
        }
        return nil
    }
    
    public func findLeaf(_ predicate:(T) -> Int) -> T? {
        var current = self.root
        while let cur = current {
            let delta = predicate(cur)
            if delta < 0 {
                if cur.right == nil {
                    return cur
                } else {
                    current = cur.right
                }
            } else if delta > 0 {
                if cur.left == nil {
                    current = cur.left
                } else {
                    return cur
                }
            } else {
                if cur.left == nil && cur.right == nil {
                    return cur
                } else {
                    return nil
                }
            }
        }
        return nil
    }
    
    public func iterateLeaves(_ handler:(T) -> Void) {
        if let root = self.root {
            self.iterateNode(root, requireLeaf: true, handler: handler)
        }
    }
    
    public func iterateNodes(_ handler:(T) -> Void) {
        if let root = self.root {
            self.iterateNode(root, requireLeaf: false, handler: handler)
        }
    }
    
    fileprivate func iterateNode(_ node:T, requireLeaf:Bool, handler:(T) -> Void) {
        if let left = node.left {
            self.iterateNode(left, requireLeaf: requireLeaf, handler: handler)
        }
        if node.isLeaf || !requireLeaf {
            handler(node)
        }
        if let right = node.right {
            self.iterateNode(right, requireLeaf: requireLeaf, handler: handler)
        }
    }

    public func getLeaves() -> [T] {
        var leaves:[T] = []
        self.iterateLeaves() { leaves.append($0) }
        return leaves
    }
    
    fileprivate static func toString(_ val:T, depth:Int) -> String {
        var tabs = ""
        for _ in 0..<depth {
            tabs += " "
        }
        var str = "\(val)\n"
        if let left = val.left {
            str += "\(tabs)L: "
            str += ExposedBinarySearchTree.toString(left, depth: depth + 1)
        }
        if let right = val.right {
            str += "\(tabs)R: "
            str += ExposedBinarySearchTree.toString(right, depth: depth + 1)
        }
        return str
    }

    fileprivate func calculateCountOf(_ node:T?, leaves:Bool) -> Int {
        if let node = node {
            return ((node.isLeaf || !leaves) ? 1 : 0) + self.calculateCountOf(node.left, leaves: leaves) + self.calculateCountOf(node.right, leaves: leaves)
        } else {
            return 0
        }
    }
    
    fileprivate func calculateLayersOf(_ node:T?) -> Int {
        if let node = node {
            return max(self.calculateLayersOf(node.left), self.calculateLayersOf(node.right)) + 1
        } else {
            return 0
        }
    }
    
}
 
