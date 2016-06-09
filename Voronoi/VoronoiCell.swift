//
//  VoronoiCell.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import OmniSwift

/**
 Combines a voronoi point and the edges / vertices around it.
 */
public class VoronoiCell {
    
    ///The original voronoi point.
    public let voronoiPoint:CGPoint
    ///The boundaries of the VoronoiDiagram.
    public let boundaries:CGSize
    ///The vertices that form the edges of this cell.
    private var vertices:[CGPoint]
    ///The actual edges that form the boundaries of this cell.
    public var cellEdges:[VoronoiCellEdge] = []
    
    ///These are needed because sometimes I need to connect
    ///2 corners but I need to disallow the same corner from
    ///being considered twice. No cell will need to connect
    ///more than 2 corners, so this is more than sufficient.
    private var usedLeftSide    = false
    ///See docs for ```usedLeftSide```.
    private var usedRightSide   = false
    ///See docs for ```usedLeftSide```.
    private var usedTopSide     = false
    ///See docs for ```usedLeftSide```.
    private var usedBottomSide  = false
    
    ///Initializes a VoronoiCell with a voronoi point and the boundaries of a VoronoiDiagram.
    public init(point:CGPoint, boundaries:CGSize) {
        self.voronoiPoint   = point
        self.vertices       = []
        self.boundaries     = boundaries
    }
    
    ///Calculates the vertices in the correct order so they can be
    ///combined to form the edges of this cell.
    public func makeVertexLoop() -> [CGPoint] {
        guard let start = self.cellEdges.first else {
            return []
        }
        let startVertices = self.seekToEndOfEdges(start, nextEdge: (start.startNeighbor, start.startPoint))
        //Inner point, we already have a loop.
        if self.verticesAreComplete(startVertices) {
            return startVertices
        }
        let endVertices = self.seekToEndOfEdges(start, nextEdge: (start.endNeighbor, start.endPoint))
        var verts = startVertices.reverse() + endVertices
//        return verts
        if let first = verts.first, last = verts.last, let corner = self.connectToCornerFirst(first, last: last) {
            verts.append(corner)
            //Sometimes, you need to connect two corners.
            if !(first.x ~= corner.x || first.y ~= corner.y) {
                if let secondCorner = self.connectToCornerFirst(first, last: corner) {
                    verts.append(secondCorner)
                }
            } else if !(last.x ~= corner.x || last.y ~= corner.y) {
                if let secondCorner = self.connectToCornerFirst(last, last: corner) {
                    //If we add the corner to the end always, we might get edges that
                    //jump to the bottom of the screen and then the top, crossing over
                    //each other. We need to insert the corners in the correct order,
                    //so we check which point it lies on a straight line with.
                    if first.liesOnAxisWith(secondCorner) {
                        verts.append(secondCorner)
                    } else {
                        //Second corner goes before first corner
                        verts.insert(secondCorner, atIndex: verts.count - 1)
                    }
                }
            }
        }
        return verts
    }
    
    private func verticesAreComplete(vertices:[CGPoint]) -> Bool {
        guard let first = vertices.first, last = vertices.last where vertices.count > 1 else {
            return false
        }
        /*if first ~= last {
            return true
        } else if first.x ~= 0.0 && last.x ~= 0.0 {
            return true
        } else if first.y ~= 0.0 && last.y ~= 0.0 {
            return true
        } else if first.x ~= self.boundaries.width && last.x ~= self.boundaries.width {
            return true
        } else if first.y ~= self.boundaries.height && last.y ~= self.boundaries.height {
            return true
        }
        return false*/
        return first.liesOnAxisWith(last)
    }
    
    /**
     Determines if the two end points of vertices (```first``` and ```last```)
     need to connect to the corner to complete the edges of this cell.
     - returns: The corner to connect the first/last points to, or nil if the
     the points already connect.
     */
    internal func connectToCornerFirst(first:CGPoint, last:CGPoint) -> CGPoint? {
        if !(first.x ~= last.x || first.y ~= last.y) {
            let x:CGFloat
            let y:CGFloat
            if first.x ~= 0.0 || last.x ~= 0.0 && !self.usedLeftSide {
                x = 0.0
                self.usedLeftSide = true
            } else {
                self.usedRightSide = true
                x = self.boundaries.width
            }
            if first.y ~= 0.0 || last.y ~= 0.0 && !self.usedBottomSide {
                y = 0.0
                self.usedBottomSide = true
            } else {
                self.usedTopSide = true
                y = self.boundaries.height
            }
            return CGPoint(x: x, y: y)
        }
        return nil
    }
    
    /**
     Iterates through a linked list of VoronoiCellEdges, adding each vertex.
     - parameters prev: The VoronoiCellEdge to start iterating at.
     - parameters nextEdge: The neighbor pair of prev determining which direction (start or end) to search in.
     */
    private func seekToEndOfEdges(prev:VoronoiCellEdge, nextEdge:(edge:VoronoiCellEdge?, vertex:CGPoint)) -> [CGPoint] {
        let frame = CGRect(size: self.boundaries)
        /*if !frame.contains(nextEdge.vertex) {
            return []
        }*/
        let first       = prev
        var vertices:[CGPoint] = []
        var previous    = prev
        var next        = nextEdge.edge
        var prevVertex  = nextEdge.vertex//(nextEdge.edge === prev.startNeighbor ? prev.startPoint : prev.endPoint)
        if let boundaryVertex = prev.intersectionWith(self.boundaries) where !(boundaryVertex ~= nextEdge.vertex) {
            //The vertex out of bounds will always be the start vertex,
            //so I don't have to worry about the end vertex (I think)!
            if frame.contains(nextEdge.vertex) {
                vertices = [boundaryVertex, nextEdge.vertex]
            } else {
                vertices = [boundaryVertex]
            }
        } else {
            if frame.contains(nextEdge.vertex) {
                vertices = [nextEdge.vertex]
            }
        }
        while let after = next {
            /*if !(frame.contains(after.startPoint) && frame.contains(after.endPoint)) {
                if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                    return vertices
                }
                return vertices
            }*/
            let successor = after.getNextFrom(previous)
            next = successor.edge
            previous = after
            
            
            if !frame.contains(after.startPoint) && frame.contains(after.endPoint) {
                if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                }
            } else if frame.contains(after.startPoint) && !frame.contains(after.endPoint) {
                if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                }
            }
            
            if frame.contains(successor.vertex) {
                vertices.append(successor.vertex)
            } else if frame.contains(prevVertex) {
                //If the frame contains the last vertex but not the next vertex,
                //it means we were in the frame but no longer are, so we want to return.
                //If both vertices are outside the frame, we want to keep going, because
                //it's valid for an entire edge to lie outside the frame; we just won't
                //add the out-of-bounds vertices.
//                return vertices
            }
            
            if after === first {
                return vertices
            }
            prevVertex = successor.vertex
        }
        return vertices
    }

}