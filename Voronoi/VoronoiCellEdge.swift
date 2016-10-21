//
//  VoronoiCellEdge.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import CoronaConvenience
import CoronaStructures
import CoronaGL

/**
 Represents an edge of a voronoi diagram that's associated with
 a specific cell. It can be connected to other VoronoiCellEdges
 to form the path that winds around the cell.
 */
internal class VoronoiCellEdge: Hashable, CustomStringConvertible {
    
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
    internal var startPointString:String { return /*self.startNeighbor == nil ? "nil" :*/ "\(self.startPoint)" }
    internal var endPointString:String { return /*self.endNeighbor == nil ? "nil" :*/ "\(self.endPoint)" }
    ///The VoronoiCell this edge is associated with.
    internal weak var owner:VoronoiCell?        = nil
    ///A unit vector pointing in the same direction as the line this edge lies on.
    internal var directionVector:CGPoint { return (self.endPoint - self.startPoint).unit() }
    
    internal var walked = false
    
    internal var startPointIndex    = -1
    internal var endPointIndex      = -1
    
    internal static var uIndex = 0
    internal let index:Int
    internal var hashValue:Int { return self.index }
    
    internal var description: String {
        return "VoronoiCellEdge(\(self.startPointString) -> \(self.endPointString))"
    }
    
    ///Initializes the edge with a given start point.
    internal init(start:CGPoint, index:Int) {
        self.startPoint = start
        self.startPointIndex = index
        
        //Used exclusively for hashing.
        //The amount of voronoi points necessary to cause
        //overflow and reach 0 again would be so absurdly high
        //that it is unfeasible to calculate such a diagram.
        VoronoiCellEdge.uIndex = VoronoiCellEdge.uIndex &+ 1
        self.index = VoronoiCellEdge.uIndex
    }
    
    /**
     Connects this edge with the neighboring edge if applicable.
     Note that edges don't necessarily have to connect start-to-start
     or end-to-end, they can also connect start-to-end.
     - parameter cellEdge: The edge to connect this edge with.
     */
    internal func makeNeighbor(_ cellEdge:VoronoiCellEdge) {
        /*
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
        */
        if self.startPointIndex == cellEdge.startPointIndex {
            self.startNeighbor = cellEdge
            cellEdge.startNeighbor = self
        } else if self.startPointIndex == cellEdge.endPointIndex {
            self.startNeighbor = cellEdge
            cellEdge.endNeighbor = self
        } else if self.endPointIndex == cellEdge.startPointIndex {
            self.endNeighbor = cellEdge
            cellEdge.startNeighbor = self
        } else if self.endPointIndex == cellEdge.endPointIndex {
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
    internal func getNextFrom(_ cellEdge:VoronoiCellEdge) -> (edge:VoronoiCellEdge?, vertex:CGPoint) {
        if self.startNeighbor === cellEdge {
            return (self.endNeighbor, self.endPoint)
        } else {
            return (self.startNeighbor, self.startPoint)
        }
    }
    
    /**
     Returns the vertex opposite this one. If the vertex corresponds
     to the start vertex, this method returns the end vertex and vice-versa.
     - parameter vertex: The vertex opposite the desired vertex.
     - returns: The vertex of this edge that is NOT the passed in vertex
     */
    internal func opposite(vertex:CGPoint) -> CGPoint {
        if self.startPoint ~= vertex {
            return self.endPoint
        } else {
            return self.startPoint
        }
    }
    
    /**
     Calculates the point at which this edge connects with the bounding rectangle
     formed by (0, 0, boundaries.width, boundaries.height). Some edges overshoot
     the boundaries, so this method is used to clamp them to the edge.
     - parameter boundaries: The size of the VoronoiDiagram.
     - returns: The point at which this edge intersects with the boundaries, or nil if it does not.
     */
    internal func intersectionWith(_ boundaries:CGSize, invert:Bool = false) -> [CGPoint] {
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
        }
        if (startPoint.x <= boundaries.width) == (boundaries.width <= endPoint.x) {
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
        }
        if (startPoint.y <= boundaries.height) == (boundaries.height <= endPoint.y) {
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
    
    /**
     Sorts an array of points according to how far
     they are from the current point. For example, if the
     algorithm is walking from (0, 3) -> (8, 3), we want
     to make sure that (0, 3) appears in the vertex array
     before (8, 3). We do this by treating the line as a
     parametric function and ordering the points by their "time"
     (making sure to take into account axis-aligned points which
     would result in division by zero errors).
    
     - parameter intersections: An array of points that intersects with the boundaries of a VoronoiDiagram.
     - parameter start: The point you are currently walking from.
     - returns: The intersections array sorted according to how close
     each point is to the start point.
     */
    internal func sort(intersections:[CGPoint], byStart start:CGPoint) -> [CGPoint] {
        //p(t) = start + vector * t
        //t = (p(t) - start) / vector
        let vector = (self.endPoint - self.startPoint).unit()
        let mapped = intersections.map() { (point:CGPoint) -> (CGPoint, CGFloat) in
            if vector.x ~= 0.0 {
                return (point, (point.y - start.y) / vector.y)
            } else if vector.y ~= 0.0 {
                return (point, (point.x - start.x) / vector.x)
            } else {
                return (point, ((point - start) / vector).length())
            }
        }
        return mapped .filter() { $1 >= 0.0 } .sorted() { $0.1 < $1.1 } .map() { $0.0 }
    }
    
    internal func edgeIsStartNeighbor(_ edge:VoronoiCellEdge) -> Bool {
        return self.startNeighbor === edge
    }
    
    internal func edgeIsEndNeighbor(_ edge:VoronoiCellEdge) -> Bool {
        return self.endNeighbor === edge
    }

}

///Used exclusively for hashing. See comment in
///initializer for further reasoning.
func ==(lhs:VoronoiCellEdge, rhs:VoronoiCellEdge) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
