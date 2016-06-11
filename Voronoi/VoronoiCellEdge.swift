//
//  VoronoiCellEdge.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import OmniSwift

/**
 Represents an edge of a voronoi diagram that's associated with
 a specific cell. It can be connected to other VoronoiCellEdges
 to form the path that winds around the cell.
 */
internal class VoronoiCellEdge {
    
    ///The VoronoiCellEdge connected to this one at this one's start point.
    internal weak var startNeighbor:VoronoiCellEdge? = nil {
        didSet {
            if oldValue != nil {
                self.endNeighbor = self.startNeighbor
                self.startNeighbor = oldValue
            }
        }
    }
    ///The VoronoiCellEdge connected to this one at this one's end point.
    internal weak var endNeighbor:VoronoiCellEdge?   = nil {
        didSet {
            if oldValue != nil {
                self.startNeighbor = self.endNeighbor
                self.endNeighbor = oldValue
            }
        }
    }
    ///The point where this edge starts.
    internal var startPoint:CGPoint             = CGPoint.zero
    ///THe point where this edge ends. It is set by the VoronoiEdge that owns it.
    internal var endPoint:CGPoint               = CGPoint.zero {
        didSet {
            self.hasSetEnd = true
        }
    }
    ///Determines if this object has a valid value for endPoint.
    internal var hasSetEnd                      = false
    ///The VoronoiCell this edge is associated with.
    internal weak var owner:VoronoiCell?        = nil
    ///A unit vector pointing in the same direction as the line this edge lies on.
    internal var directionVector:CGPoint { return (self.endPoint - self.startPoint).unit() }

    ///Initializes the edge with a given start point.
    internal init(start:CGPoint) {
        self.startPoint = start
    }
    
    /**
     Connects this edge with the neighboring edge if applicable.
     Note that edges don't necessarily have to connect start-to-start
     or end-to-end, they can also connect start-to-end.
     - parameter cellEdge: The edge to connect this edge with.
     */
    internal func makeNeighbor(cellEdge:VoronoiCellEdge) {
        
        if self.startPoint ~= cellEdge.startPoint {
            self.startNeighbor = cellEdge
            cellEdge.startNeighbor = self
        } else if self.startPoint ~= cellEdge.endPoint {
            self.startNeighbor = cellEdge
            cellEdge.endNeighbor = self
        } else if self.endPoint ~= cellEdge.startPoint {
            self.endNeighbor = cellEdge
            cellEdge.startNeighbor = self
        } else if self.endPoint ~= cellEdge.endPoint {
            self.endNeighbor = cellEdge
            cellEdge.endNeighbor = self
        }
    }
    
    /**
     Returns the neighboring edge that is NOT the given cellEdge. Used to iterate
     through neighboring VoronoiCellEdges. For example, if this edge's startNeighbor
     is the given edge, the next neighbor you want is the end neighbor, and vice-versa.
     - parameter cellEdge: A VoronoiCellEdge that neighbors this one.
     - returns: The VoronoiCellEdge that neighbors this one but is not the given one, and the
     vertex at which the edges connect (either startPoint or endPoint).
     */
    internal func getNextFrom(cellEdge:VoronoiCellEdge) -> (edge:VoronoiCellEdge?, vertex:CGPoint) {
        if self.startNeighbor === cellEdge {
            return (self.endNeighbor, self.endPoint)
        } else {
            return (self.startNeighbor, self.startPoint)
        }
    }
    
    /**
     Calculates the point at which this edge connects with the bounding rectangle
     formed by (0, 0, boundaries.width, boundaries.height). Some edges overshoot
     the boundaries, so this method is used to clamp them to the edge.
     - parameter boundaries: The size of the VoronoiDiagram.
     - returns: The point at which this edge intersects with the boundaries, or nil if it does not.
     */
    internal func intersectionWith(boundaries:CGSize, invert:Bool = false) -> [CGPoint] {
        let startPoint = invert ? self.endPoint : self.startPoint
        let endPoint = invert ? self.startPoint : self.endPoint
        let vector = (endPoint - startPoint)
        var intersections:[CGPoint] = []
        //Horizontal boundaries
        if (startPoint.x <= 0.0) == (0.0 <= endPoint.x) {
            //Edge crosses line x = 0
            let t = -startPoint.x / vector.x
            let y = vector.y * t + startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(CGPoint(x: 0.0, y: y))
            }
        } else if (startPoint.x <= boundaries.width) == (boundaries.width <= endPoint.x) {
            //Edge crosses line x = boundaries.width
            let t = (boundaries.width - startPoint.x) / vector.x
            let y = vector.y * t + startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(CGPoint(x: boundaries.width, y: y))
            }
        }
        
        //Vertical boundaries
        if (startPoint.y <= 0.0) == (0.0 <= endPoint.y) {
            //Edge crosses line x = 0
            let t = -startPoint.y / vector.y
            let x = vector.x * t + startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(CGPoint(x: x, y: 0.0))
            }
        } else if (startPoint.y <= boundaries.height) == (boundaries.height <= endPoint.y) {
            //Edge crosses line y = boundaries.height
            let t = (boundaries.height - startPoint.y) / vector.y
            let x = vector.x * t + startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                intersections.append(CGPoint(x: x, y: boundaries.height))
            }
        }
        
        return intersections
    }
    
    internal func edgeIsStartNeighbor(edge:VoronoiCellEdge) -> Bool {
        return self.startNeighbor === edge
    }
    
    internal func edgeIsEndNeighbor(edge:VoronoiCellEdge) -> Bool {
        return self.endNeighbor === edge
    }

}