//
//  VoronoiEdge.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

/**
 Represents an edge formed by the intersection of the parabolas.
 */
internal class VoronoiEdge: CustomStringConvertible {
    
    ///The initial point at which the two parabolas intersected.
    internal let startPoint:Point
    
    ///The final point at which the two parabolas intersected (this is either
    ///set during a CircleEvent or extrapolated to the edge of the VoronoiDiagram
    ///at the end of the sweep)
    internal var endPoint:Point = Point.zero {
        didSet {
            self.hasSetEnd = true
        }
    }
    ///The focus of the left parabola.
    internal let left:Point
    ///The focus of the right parabola.
    internal let right:Point
    ///The left parabola that forms this edge via intersection with another parabola.
    internal weak var leftParabola:VoronoiParabola? = nil {
        didSet {
            self.leftParabola?.rightEdge = self
        }
    }
    ///The right parabola that forms this edge via intersection with another parabola.
    internal weak var rightParabola:VoronoiParabola? = nil {
        didSet {
            self.rightParabola?.leftEdge = self
        }
    }
    ///The left parabola's underlying cell.
    internal unowned let leftCell:VoronoiCell
    ///The right parabola's underlying cell.
    internal unowned let rightCell:VoronoiCell
    
    ///The slope of the line that this edge lies on.
    internal var slope:Double {
        //Negative recipricol to get the actual slope perpendicular to the focii.
        return (self.right.x - self.left.x) / (self.left.y - self.right.y)
    }
    ///The y-intercept of the line that this edge lies on.
    internal var yIntercept:Double {
        return self.startPoint.y - self.slope * self.startPoint.x
    }
    ///The vector pointing in the direction of the line this edge lies on.
    internal var directionVector:Point {
        //Direction is perpendicular to the two focii corresponding to the left/right points.
        return Point(x: self.right.y - self.left.y, y: self.left.x - self.right.x)
    }
    
    ///When the VoronoiDiagram sets the end point, this is set to true.
    internal var hasSetEnd = false
    
    internal var description: String {
        if self.hasSetEnd {
            return "VoronoiEdge(\(self.startPoint) -> \(self.endPoint))"
        } else {
            return "VoronoiEdge(\(self.startPoint) Dir(\(self.directionVector)))"
        }
    }
    
    ///Initializes a VoronoiEdge with a start point and the cells
    ///(which contain the focii/parabola)on either side.
    internal init(start:Point, left:VoronoiCell, right:VoronoiCell) {
        self.startPoint = start
        self.leftCell   = left
        self.rightCell  = right
        self.left       = left.voronoiPoint
        self.right      = right.voronoiPoint
        
        left.cellEdges.append(self)
        right.cellEdges.append(self)
    }
    
    /**
     Calculates the point at which this edge connects with the bounding rectangle
     formed by (0, 0, boundaries.width, boundaries.height). Some edges overshoot
     the boundaries, so this method is used to clamp them to the edge.
     - parameter boundaries: The size of the VoronoiDiagram.
     - returns: The point at which this edge intersects with the boundaries, or nil if it does not.
     */
    internal func intersectionWith(_ boundaries:Size) -> [Point] {
        let startPoint = self.startPoint
        let endPoint = self.endPoint
        let vector = (endPoint - startPoint)
        var intersections:[Point] = []
        //Horizontal boundaries
        if (startPoint.x <= 0.0) == (0.0 <= endPoint.x) {
            //Edge crosses line x = 0
            let t = -startPoint.x / vector.x
            let y = vector.y * t + startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(Point(x: 0.0, y: y))
            }
        }
        if (startPoint.x <= boundaries.width) == (boundaries.width <= endPoint.x) {
            //Edge crosses line x = boundaries.width
            let t = (boundaries.width - startPoint.x) / vector.x
            let y = vector.y * t + startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(Point(x: boundaries.width, y: y))
            }
        }
        
        //Vertical boundaries
        if (startPoint.y <= 0.0) == (0.0 <= endPoint.y) {
            //Edge crosses line x = 0
            let t = -startPoint.y / vector.y
            let x = vector.x * t + startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(Point(x: x, y: 0.0))
            }
        }
        if (startPoint.y <= boundaries.height) == (boundaries.height <= endPoint.y) {
            //Edge crosses line y = boundaries.height
            let t = (boundaries.height - startPoint.y) / vector.y
            let x = vector.x * t + startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(Point(x: x, y: boundaries.height))
            }
        }
        
        return intersections
    }

}

