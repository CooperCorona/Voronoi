//
//  VoronoiParabola.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/7/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import UIKit
import OmniSwift

/**
 Represents a parabola that is part of the beach line for Fortune's algorithm.
 Stores the edges connected to this parabola and the cell associated with its focus.
 Also acts as a node for a binary search tree.
 */
public  final class VoronoiParabola: ExposedBinarySearchTreeProtocol {
    
    ///The cell associated with this parabola's focus.
    public  let cell:VoronoiCell
    
    ///The focus of the parabola (the actual voronoi point).
    public  let focus:CGPoint
    
    ///The directrix of the parabola (VoronoiDiagram sets this to its sweepLine property).
    public  var directix:CGFloat = 0.0
    
    ///The circle event associated with this parabola. When the circle event is
    ///processed, this parabola is removed from the tree.
    public  var circleEvent:VoronoiCircleEvent? = nil {
        didSet {
            if oldValue?.parabola === self {
                oldValue?.parabola = nil
            }
        }
    }
    ///The edge formed by the left intersection of this parabola.
    public  var leftEdge:VoronoiEdge?    = nil
    ///The edge formed by the right intersection of this parabola.
    public  var rightEdge:VoronoiEdge?   = nil
    
    ///The left child of this parabola (as a node in a binary search tree).
    public  var left:VoronoiParabola?    = nil {
        didSet {
            self.left?.parent = self
        }
    }
    ///The right child of this parabola (as a node in a binary search tree).
    public  var right:VoronoiParabola?   = nil {
        didSet {
            self.right?.parent = self
        }
    }
    ///The parent of this parabola (as a node in a binary search tree).
    public  var parent:VoronoiParabola?  = nil

    ///Initializes a parabola with an associated cell (and underlying VoronoiPoint).
    public  init(cell:VoronoiCell) {
        self.cell       = cell
        self.focus      = cell.voronoiPoint
        self.directix   = cell.voronoiPoint.y
        
        if self.focus.x ~= 330.9807 && self.focus.y ~= 864.01934 {
            print("f")
        }
    }
    
    /**
     Gets the y-value for a given x-value. You must set the directrix
     property before invoking this method.
     - parameter x: The x-value.
     - returns: The y-value corresponding to the x-value.
     */
    public  func yForX(x:CGFloat) -> CGFloat {
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
    public  class func parabolaCollisions(focus1:CGPoint, focus2:CGPoint, directrix:CGFloat) -> [CGPoint] {
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
            return [CGPoint(x: x, y: y), CGPoint(x: x, y: y)]
        } else if p1 ~= 0.0 {
            let parab = VoronoiParabola(cell: VoronoiCell(point: focus2, boundaries: CGSize.zero))
            let point = CGPoint(x: focus1.x, y: parab.yForX(focus1.x))
            return [point, point]
        } else if p2 ~= 0.0 {
            let parab = VoronoiParabola(cell: VoronoiCell(point: focus1, boundaries: CGSize.zero))
            let point = CGPoint(x: focus2.x, y: parab.yForX(focus2.x))
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
            return [CGPoint(x: x, y: y), CGPoint(x: x, y: y)]
        }
        let xNeg = (-b - sqrt(radical)) / (2.0 * a)
        let xPos = (-b + sqrt(radical)) / (2.0 * a)
        let yNeg = (xNeg - h1) * (xNeg - h1) / (4.0 * p1) + k1
        let yPos = (xPos - h1) * (xPos - h1) / (4.0 * p1) + k1
        return [CGPoint(x: xNeg, y: yNeg), CGPoint(x: xPos, y: yPos)]
    }

    ///Gets the parabola that is to the left of this parabola on the beach line.
    public  func getParabolaToLeft() -> VoronoiParabola? {
        return self.getLeftmostParent()?.getNearestLeftChild()
    }
    
    ///Gets the parabola that is to the right of this parabola on the beach line.
    public  func getParabolaToRight() -> VoronoiParabola? {
        return self.getRightmostParent()?.getNearestRightChild()
    }
    
}

// MARK: - Comparable Protocol / ExposedBinarySearchTreeProtocol

public  func ==(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus == rhs.focus
}

public  func <(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y < rhs.focus.y
}

public  func >(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y > rhs.focus.y
}

public  func <=(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y <= rhs.focus.y
}

public  func >=(lhs:VoronoiParabola, rhs:VoronoiParabola) -> Bool {
    return lhs.focus.y >= rhs.focus.y
}
