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
    private var vertices:[CGPoint]? = nil
    ///The actual edges that form the boundaries of this cell.
    internal var cellEdges:[VoronoiCellEdge] = []
    
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
        self.boundaries     = boundaries
    }
    
    ///Calculates the vertices in the correct order so they can be
    ///combined to form the edges of this cell.
    public func makeVertexLoop() -> [CGPoint] {
        if let vertices = self.vertices {
            return vertices
        }
        guard let start = self.cellEdges.first else {
            return []
        }
        start.setVoronoiPointLiesAbove(self.voronoiPoint)
        let (complete, startVertices, lastStart) = self.seekToEndOfEdges(start, nextEdge: (start.startNeighbor, start.startPoint))
        //Inner point, we already have a loop.
        if complete || self.verticesAreComplete(startVertices) {
            return startVertices
        }
        let (_, endVertices, lastEnd) = self.seekToEndOfEdges(start, nextEdge: (start.endNeighbor, start.endPoint))
//        var verts = startVertices.reverse() + endVertices
        var verts:[CGPoint] = startVertices.reverse()
        if !complete && !self.verticesAreComplete(startVertices) {
            verts += endVertices
        }
        verts = self.removeDuplicates(verts)
        /*if let first = verts.first, last = verts.last, let corner = self.connectToCornerFirst(first, last: last) {
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
        }*/
        /*if let first = verts.first, last = verts.last, startLast = lastStart, endLast = lastEnd {
//            verts += self.connectToCornersFirst(first, last: last, startLast: lastStart, endLast: lastEnd)
            let connector = VoronoiCornerConnector(voronoiPoint: self.voronoiPoint, boundaries: self.boundaries)
            verts += connector.connectFirst_2(first, toLast: last, startLine: startLast, endLine: endLast)
         }*/
        let connector = VoronoiCornerConnector(voronoiPoint: self.voronoiPoint, boundaries: self.boundaries)
        verts += connector.connectToCorners(verts)
        self.vertices = verts
        return verts
    }
    
    private func verticesAreComplete(vertices:[CGPoint]) -> Bool {
        guard let first = vertices.first, last = vertices.last where vertices.count > 1 else {
            return false
        }
        return first.liesOnAxisWith(last) && !(first ~= last)
    }
    
    private func point(point:CGPoint, liesAbove line:VoronoiCellEdge) -> Bool {
        //y = mx + b
        //y - mx = b
        //Above: y - mx > b
        //Below: y - mx < b
        return point.y - line.slope * point.x > line.yIntercept
    }
    
    private func handleAxisLines(first:CGPoint, last:CGPoint, startLast:VoronoiCellEdge, endLast:VoronoiCellEdge) -> [CGPoint]? {
        guard first.liesOnAxisWith(last) else {
            return nil
        }
        if (first.x ~= 0.0 && last.x ~= self.boundaries.width) || (first.x ~= self.boundaries.width && last.x ~= 0.0) {
            if self.voronoiPoint.y < first.y {
                //Bottom
                if last.x ~= 0.0 {
                    //Left first
                    return [CGPoint.zero, CGPoint(x: self.boundaries.width, y: 0.0)]
                } else {
                    //Right first
                    return [CGPoint(x: self.boundaries.width, y: 0.0), CGPoint.zero]
                }
            } else {
                //Top
                if last.x ~= 0.0 {
                    //Left first
                    return [CGPoint(x: 0.0, y: self.boundaries.height), CGPoint(x: self.boundaries.width, y: self.boundaries.height)]
                } else {
                    //Right first
                    return [CGPoint(x: self.boundaries.width, y: self.boundaries.height), CGPoint(x: 0.0, y: self.boundaries.height)]
                }
            }
        } else if (first.y ~= 0.0 && last.y ~= self.boundaries.height) || (first.y ~= self.boundaries.height && last.y ~= 0.0) {
            if self.voronoiPoint.x < first.x {
                //Left
                if last.y ~= 0.0 {
                    //Bottom first
                    return [CGPoint.zero, CGPoint(x: 0.0, y: self.boundaries.height)]
                } else {
                    //Top first
                    return [CGPoint(x: 0.0, y: self.boundaries.height), CGPoint.zero]
                }
            } else {
                //Right
                if last.y ~= 0.0 {
                    //Bottom first
                    return [CGPoint(x: self.boundaries.width, y: 0.0), CGPoint(x: self.boundaries.width, y: self.boundaries.height)]
                } else {
                    //Top first
                    return [CGPoint(x: self.boundaries.width, y: self.boundaries.height), CGPoint(x: self.boundaries.width, y: 0.0)]
                }
            }
        }
        return nil
    }
    
    private func removeDuplicates(vertices:[CGPoint]) -> [CGPoint] {
        var i = 0
        var filteredVertices = vertices
        while i < filteredVertices.count - 1 {
            if filteredVertices[i] ~= filteredVertices[i + 1] {
                filteredVertices.removeAtIndex(i + 1)
            } else {
                i += 1
            }
        }
        return filteredVertices
    }
    /**
     Iterates through a linked list of VoronoiCellEdges, adding each vertex.
     - parameters prev: The VoronoiCellEdge to start iterating at.
     - parameters nextEdge: The neighbor pair of prev determining which direction (start or end) to search in.
     */
    private func seekToEndOfEdges(prev:VoronoiCellEdge, nextEdge:(edge:VoronoiCellEdge?, vertex:CGPoint)) -> (complete:Bool, points:[CGPoint], last:VoronoiCellEdge?) {
        let frame = CGRect(size: self.boundaries)
        let first       = prev
        var vertices:[CGPoint] = []
        var previous    = prev
        var next        = nextEdge.edge
        var prevVertex  = nextEdge.vertex//(nextEdge.edge === prev.startNeighbor ? prev.startPoint : prev.endPoint)
        let boundaryVertices = prev.intersectionWith(self.boundaries)
        vertices += boundaryVertices
        if frame.contains(nextEdge.vertex) {
            vertices.append(nextEdge.vertex)
        }
        /*if let boundaryVertex = prev.intersectionWith(self.boundaries) where !(boundaryVertex ~= nextEdge.vertex) {
            //The vertex out of bounds will always be the start vertex,
            //so I don't have to worry about the end vertex (I think)!
            if frame.contains(nextEdge.vertex) {
                vertices = [boundaryVertex, nextEdge.vertex]
            } else {
                vertices = [boundaryVertex]
            }
            if !frame.contains(prev.startPoint) && !frame.contains(prev.endPoint) {
                if let otherBoundary = prev.intersectionWith(self.boundaries, invert: true) {
                    vertices.insert(otherBoundary, atIndex: 0)
                }
            }
            print(vertices)
        } else {
            if frame.contains(nextEdge.vertex) {
                vertices = [nextEdge.vertex]
            }
        }*/
        var last:VoronoiCellEdge? = nil
        while let after = next {
            after.setVoronoiPointLiesAbove(self.voronoiPoint)
            
            let successor = after.getNextFrom(previous)
            next = successor.edge
            previous = after
            
            if after === first {
                return (true, vertices, previous)
            }
            
            if !frame.contains(after.startPoint) && frame.contains(after.endPoint) {
                for bv in after.intersectionWith(self.boundaries) {
                    vertices.append(bv)
                }
                last = after
                /*if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                }*/
            } else if frame.contains(after.startPoint) && !frame.contains(after.endPoint) {
                for bv in after.intersectionWith(self.boundaries) {
                    vertices.append(bv)
                }
                last = after
                /*if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                }*/
            } else if !frame.contains(after.startPoint) && !frame.contains(after.endPoint) {
                let intersections = after.intersectionWith(self.boundaries)
                for bv in intersections {
                    vertices.append(bv)
                }
                if intersections.count > 0 {
                    last = after
                }
                /*if let boundaryVertex = after.intersectionWith(self.boundaries) {
                    vertices.append(boundaryVertex)
                    print(boundaryVertex)
                }
                if let boundaryVertex = after.intersectionWith(self.boundaries, invert: true) {
                    vertices.append(boundaryVertex)
                    print(boundaryVertex)
                }*/
            }
            
            if frame.contains(successor.vertex) {
                vertices.append(successor.vertex)
            } else if frame.contains(prevVertex) {
                //If the frame contains the last vertex but not the next vertex,
                //it means we were in the frame but no longer are, so we want to return.
                //If both vertices are outside the frame, we want to keep going, because
                //it's valid for an entire edge to lie outside the frame; we just won't
                //add the out-of-bounds vertices.
                last = after
                return (false, vertices, last)
            }
            
            prevVertex = successor.vertex
        }
        return (false, vertices, last)
    }

}