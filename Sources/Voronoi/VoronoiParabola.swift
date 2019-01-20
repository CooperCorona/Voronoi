//
//  VoronoiParabola.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/7/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

/**
 Represents a parabola that is part of the beach line for Fortune's algorithm.
 Stores the edges connected to this parabola and the cell associated with its focus.
 Also acts as a node for a binary search tree.
 */
internal final class VoronoiParabola: ExposedBinarySearchTreeProtocol, CustomStringConvertible {
    
    ///The cell associated with this parabola's focus.
    internal let cell:VoronoiCell
    
    ///The focus of the parabola (the actual voronoi point).
    internal let focus:Point
    
    ///The directrix of the parabola (VoronoiDiagram sets this to its sweepLine property).
    internal var directix:Double = 0.0
    
    ///The circle event associated with this parabola. When the circle event is
    ///processed, this parabola is removed from the tree.
    internal var circleEvent:VoronoiCircleEvent? = nil {
        didSet {
            if oldValue?.parabola === self {
                oldValue?.parabola = nil
            }
        }
    }
    ///The edge formed by the left intersection of this parabola.
    internal weak var leftEdge:VoronoiEdge?    = nil
    ///The edge formed by the right intersection of this parabola.
    internal weak var rightEdge:VoronoiEdge?   = nil
    
    ///The left child of this parabola (as a node in a binary search tree).
    internal var left:VoronoiParabola?    = nil {
        didSet {
            self.left?.parent = self
        }
    }
    ///The right child of this parabola (as a node in a binary search tree).
    internal var right:VoronoiParabola?   = nil {
        didSet {
            self.right?.parent = self
        }
    }
    ///The parent of this parabola (as a node in a binary search tree).
    internal weak var parent:VoronoiParabola?  = nil

    ///Initializes a parabola with an associated cell (and underlying VoronoiPoint).
    internal init(cell:VoronoiCell) {
        self.cell       = cell
        self.focus      = cell.voronoiPoint
        self.directix   = cell.voronoiPoint.y
    }

    internal var description: String {
        return "\(self.cell.voronoiPoint)"
    }
    
    /**
     Gets the y-value for a given x-value. You must set the directrix
     property before invoking this method.
     - parameter x: The x-value.
     - returns: The y-value corresponding to the x-value.
     */
    internal func yForX(_ x:Double) -> Double {
        let xMinusH = (x - self.focus.x) * (x - self.focus.x)
        let p = (self.focus.y - self.directix) / 2.0
        return xMinusH / (4.0 * p) + (self.focus.y + self.directix) / 2.0
    }
    
    /**
     Returns the collisions of the parabolas with focus1 and focus2 which both have a given directrix.
     - parameter focus1: The focus of the first parabola.
     - parameter focus2: The focus of the second parabola.
     - returns: The points at which the two parabolas collide. There will always be two points,
     unless the parabolas don't collide, in which case an empty array is returned.
     */
    internal class func parabolaCollisions(_ focus1:Point, focus2:Point, directrix:Double) -> [Point] {
        let p1 = (focus1.y - directrix) / 2.0
        let p2 = (focus2.y - directrix) / 2.0
        let h1 = focus1.x
        let k1 = (focus1.y + directrix) / 2.0
        let h2 = focus2.x
        let k2 = (focus2.y + directrix) / 2.0
        
        if p1 ~= p2 {
            let numerator = 4.0 * p1 * (k2 - k1) - h2 * h2 + h1 * h1
            let denominator = 2.0 * (h1 - h2)
            let x = numerator / denominator
            let y = (x - h1) * (x - h1) / (4.0 * p1) + k1
            return [Point(x: x, y: y), Point(x: x, y: y)]
        } else if p1 ~= 0.0 {
            let parab = VoronoiParabola(cell: VoronoiCell(point: focus2, boundaries: Size.zero))
            let point = Point(x: focus1.x, y: parab.yForX(focus1.x))
            return [point, point]
        } else if p2 ~= 0.0 {
            let parab = VoronoiParabola(cell: VoronoiCell(point: focus1, boundaries: Size.zero))
            let point = Point(x: focus2.x, y: parab.yForX(focus2.x))
            return [point, point]
        }
        
        let a = (1.0 / p1 - 1.0 / p2)
        let b = 2.0 * (h2 / p2 - h1 / p1)
        let c = 4.0 * (k1 - k2) + h1 * h1 / p1 - h2 * h2 / p2
        let radical = b * b - 4 * a * c
        if radical < 0.0 {
            return []
        } else if radical == 0.0 {
            let x = -b / (2.0 * a)
            let y = (x - h1) * (x - h1) / (4.0 * p1) + k1
            return [Point(x: x, y: y), Point(x: x, y: y)]
        }
        let xNeg = (-b - sqrt(radical)) / (2.0 * a)
        let xPos = (-b + sqrt(radical)) / (2.0 * a)
        let yNeg = (xNeg - h1) * (xNeg - h1) / (4.0 * p1) + k1
        let yPos = (xPos - h1) * (xPos - h1) / (4.0 * p1) + k1
        return [Point(x: xNeg, y: yNeg), Point(x: xPos, y: yPos)]
    }

    ///Gets the parabola that is to the left of this parabola on the beach line.
    internal func getParabolaToLeft() -> VoronoiParabola? {
        return self.getLeftmostParent()?.getNearestLeftChild()
    }
    
    ///Gets the parabola that is to the right of this parabola on the beach line.
    internal func getParabolaToRight() -> VoronoiParabola? {
        return self.getRightmostParent()?.getNearestRightChild()
    }
    
}

// MARK: - Comparable Protocol / ExposedBinarySearchTreeProtocol

internal func ==(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus == rhs.focus
}

internal func <(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y < rhs.focus.y
}

internal func >(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y > rhs.focus.y
}

internal func <=(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y <= rhs.focus.y
}

internal func >=(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y >= rhs.focus.y
}
