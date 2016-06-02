//
//  VoronoiCell.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import OmniSwift

internal class VoronoiCellEdge {
    
    internal weak var startNeighbor:VoronoiCellEdge? = nil
    internal weak var endNeighbor:VoronoiCellEdge?   = nil
    internal var startPoint:CGPoint             = CGPoint.zero
    internal var endPoint:CGPoint               = CGPoint.zero {
        didSet {
            self.hasSetEnd = true
        }
    }
    internal var hasSetEnd                      = false
    internal weak var owner:VoronoiCell?        = nil
    internal var directionVector:CGPoint { return (self.endPoint - self.startPoint).unit() }
    
    internal init(start:CGPoint) {
        self.startPoint = start
    }
    
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
    
    internal func getNextFrom(cellEdge:VoronoiCellEdge) -> (edge:VoronoiCellEdge?, vertex:CGPoint) {
        if self.startNeighbor === cellEdge {
            return (self.endNeighbor, self.endPoint)
        } else {
            return (self.startNeighbor, self.startPoint)
        }
    }
    
    internal func intersectionWith(boundaries:CGSize) -> CGPoint? {
        let vector = self.endPoint - self.startPoint
        //Horizontal boundaries
        if (self.startPoint.x <= 0.0) == (0.0 <= self.endPoint.x) {
            //Edge crosses line x = 0
            let t = -self.startPoint.x / vector.x
            let y = vector.y * t + self.startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                return CGPoint(x: 0.0, y: y)
            }
        } else if (self.startPoint.x <= boundaries.width) == (boundaries.width <= self.endPoint.x) {
            //Edge crosses line x = boundaries.width
            let t = (boundaries.width - self.startPoint.x) / vector.x
            let y = vector.y * t + self.startPoint.y
            if 0.0 <= y && y <= boundaries.height {
                //Point crosses the edge that actually lies on the boundaries
                return CGPoint(x: boundaries.width, y: y)
            }
        }
        
        //Vertical boundaries
        if (self.startPoint.y <= 0.0) == (0.0 <= self.endPoint.y) {
            //Edge crosses line x = 0
            let t = -self.startPoint.y / vector.y
            let x = vector.x * t + self.startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                return CGPoint(x: x, y: 0.0)
            }
        } else if (self.startPoint.y <= boundaries.height) == (boundaries.height <= self.endPoint.y) {
            //Edge crosses line y = boundaries.height
            let t = (boundaries.height - self.startPoint.y) / vector.y
            let x = vector.x * t + self.startPoint.x
            if 0.0 <= x && x <= boundaries.width {
                //Point crosses the edge that actually lies on the boundaries
                return CGPoint(x: x, y: boundaries.height)
            }
        }
        
        return nil
    }
    
}

public class VoronoiCell {
    
    public enum Error: ErrorType {
        case NoEdges
    }
    
    public let voronoiPoint:CGPoint
    public let boundaries:CGSize
    internal var vertices:[CGPoint]
    internal var cellEdges:[VoronoiCellEdge] = []
    
    ///These are needed because sometimes I need to connect
    ///2 corners but I need to disallow the same corner from
    ///being considered twice. No cell will need to connect
    ///more than 2 corners, so this is more than sufficient.
    private var usedLeftSide    = false
    private var usedRightSide   = false
    private var usedTopSide     = false
    private var usedBottomSide  = false
    
    public init(point:CGPoint, boundaries:CGSize) {
        self.voronoiPoint   = point
        self.vertices       = []
        self.boundaries     = boundaries
    }
    
    public func triangleFanVertices() -> [(first:CGPoint, second:CGPoint, third:CGPoint)] {
        var verts:[(first:CGPoint, second:CGPoint, third:CGPoint)] = []
        for (i, vertex) in self.vertices.enumerateSkipLast() {
            verts.append((self.voronoiPoint, vertex, self.vertices[i + 1]))
        }
        if let first = self.vertices.first, last = self.vertices.last {
            verts.append((self.voronoiPoint, last, first))
        }
        return verts
    }
    
    public func makeVertexLoop() throws -> [CGPoint] {
        guard let start = self.cellEdges.first else {
            throw Error.NoEdges
        }
        /*
        var vertices:[CGPoint]
        var next:VoronoiCellEdge?
        if start.startNeighbor != nil{
            vertices    = [start.startPoint]
            next        = start.startNeighbor
        } else if start.endNeighbor != nil {
            vertices    = [start.endPoint]
            next        = start.endNeighbor
        } else {
            throw Error.NoEdges
        }
        var previous    = start
        while let after = next {
            if after === start {
                return vertices
            }
            let tuple   = after.getNextFrom(previous)
            next        = tuple.edge
            previous    = after
            vertices.append(tuple.vertex)
        }
        throw Error.NoLoop
        */
        let startVertices = self.seekToEndOfEdges(start, nextEdge: (start.startNeighbor, start.startPoint))
        //Inner point, we already have a loop.
        if startVertices.count == self.cellEdges.count + 1 {
            return startVertices
        }
        let endVertices = self.seekToEndOfEdges(start, nextEdge: (start.endNeighbor, start.endPoint))
        var verts = startVertices.reverse() + endVertices
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
    
    private func seekToEndOfEdges(prev:VoronoiCellEdge, nextEdge:(edge:VoronoiCellEdge?, vertex:CGPoint)) -> [CGPoint] {
        let frame = CGRect(width: 1024.0, height: 1366.0)
//        if let nEdge = nextEdge.edge where !(frame.contains(nEdge.startPoint) && frame.contains(nEdge.endPoint)) {
        if !frame.contains(nextEdge.vertex) {
            return []
        }
        let first       = prev
        var vertices    = [nextEdge.vertex]
        var previous    = prev
        var next        = nextEdge.edge
        if let boundaryVertex = prev.intersectionWith(self.boundaries) {
            //The vertex out of bounds will always be the start vertex,
            //so I don't have to worry about the end vertex (I think)!
            vertices = [boundaryVertex, nextEdge.vertex]
        }
        while let after = next {
            if !(frame.contains(after.startPoint) && frame.contains(after.endPoint)) {
                if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                    return vertices
                }
                return vertices
            }
            let successor = after.getNextFrom(previous)
            next = successor.edge
            previous = after
            vertices.append(successor.vertex)
            if let boundaryVertex = after.intersectionWith(self.boundaries) {
                vertices.append(boundaryVertex)
                return vertices
            }
            if after === first {
                return vertices
            }
        }
        return vertices
    }

}