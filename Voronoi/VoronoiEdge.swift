//
//  VoronoiEdge.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import CoronaConvenience
import CoronaStructures
import CoronaGL

/**
 Represents an edge formed by the intersection of the parabolas.
 */
internal class VoronoiEdge {
    
    ///The initial point at which the two parabolas intersected.
    internal let startPoint:CGPoint
    
    ///The final point at which the two parabolas intersected (this is either
    ///set during a CircleEvent or extrapolated to the edge of the VoronoiDiagram
    ///at the end of the sweep)
    internal var endPoint:CGPoint = CGPoint.zero {
        didSet {
            self.hasSetEnd = true
            self.leftCellEdge.endPoint = self.endPoint
            self.rightCellEdge.endPoint = self.endPoint
        }
    }
    ///The focus of the left parabola.
    internal let left:CGPoint
    ///The focus of the right parabola.
    internal let right:CGPoint
    ///The left parabola that forms this edge via intersection with another parabola.
    internal var leftParabola:VoronoiParabola? = nil {
        didSet {
            self.leftParabola?.rightEdge = self
        }
    }
    ///The right parabola that forms this edge via intersection with another parabola.
    internal var rightParabola:VoronoiParabola? = nil {
        didSet {
            self.rightParabola?.leftEdge = self
        }
    }
    ///The left parabola's underlying cell.
    internal let leftCell:VoronoiCell
    ///The right parabola's underlying cell.
    internal let rightCell:VoronoiCell
    ///The left cell's edge that corresponds to this edge.
    internal let leftCellEdge:VoronoiCellEdge
    ///The right cell's edge that corresponds to this edge.
    internal let rightCellEdge:VoronoiCellEdge
    
    ///The slope of the line that this edge lies on.
    internal var slope:CGFloat {
        //Negative recipricol to get the actual slope perpendicular to the focii.
        return (self.right.x - self.left.x) / (self.left.y - self.right.y)
    }
    ///The y-intercept of the line that this edge lies on.
    internal var yIntercept:CGFloat {
        return self.startPoint.y - self.slope * self.startPoint.x
    }
    ///The vector pointing in the direction of the line this edge lies on.
    internal var directionVector:CGPoint {
        //Direction is perpendicular to the two focii corresponding to the left/right points.
        return CGPoint(x: self.right.y - self.left.y, y: self.left.x - self.right.x)
    }
    
    ///When the VoronoiDiagram sets the end point, this is set to true.
    internal var hasSetEnd = false
    
    ///Initializes a VoronoiEdge with a start point and the cells
    ///(which contain the focii/parabola)on either side.
    internal init(start:CGPoint, left:VoronoiCell, right:VoronoiCell) {
        self.startPoint = start
        self.leftCell   = left
        self.rightCell  = right
        self.left       = left.voronoiPoint
        self.right      = right.voronoiPoint
        
        let leftEdge    = VoronoiCellEdge(start: start)
        let rightEdge   = VoronoiCellEdge(start: start)
        leftEdge.owner  = self.leftCell
        rightEdge.owner = self.rightCell
        self.leftCell.cellEdges.append(leftEdge)
        self.rightCell.cellEdges.append(rightEdge)
        self.leftCellEdge = leftEdge
        self.rightCellEdge = rightEdge
    }
    
    ///Connects the start/end points of VoronoiCellEdge properties
    ///that are associated with the same cell (so they can be used
    ///to form a loop at the end of the sweep).
    internal func makeNeighborsWith(edge:VoronoiEdge) {
        if self.leftCell === edge.leftCell {
            self.leftCellEdge.makeNeighbor(edge.leftCellEdge)
        } else if self.leftCell === edge.rightCell {
            self.leftCellEdge.makeNeighbor(edge.rightCellEdge)
        }
        
        if self.rightCell === edge.leftCell {
            self.rightCellEdge.makeNeighbor(edge.leftCellEdge)
        } else if self.rightCell === edge.rightCell {
            self.rightCellEdge.makeNeighbor(edge.rightCellEdge)
        }
    }
    
    ///Invokes ```makeNeighborsWith``` for all three combinations of the given edges.
    internal class func makeNeighborsFirst(first:VoronoiEdge, second:VoronoiEdge, third:VoronoiEdge) {
        first.makeNeighborsWith(second)
        first.makeNeighborsWith(third)
        second.makeNeighborsWith(third)
    }
    
}
 