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
        
        let (complete, startVertices) = self.seekToEndOfEdges(start, nextEdge: (start.startNeighbor, start.startPoint))
        //Inner cell, we already have a loop.
        if complete || self.verticesAreComplete(startVertices) {
            return startVertices
        }
        let (_, endVertices) = self.seekToEndOfEdges(start, nextEdge: (start.endNeighbor, start.endPoint))
        var verts = startVertices.reverse() + endVertices
        verts = self.removeDuplicates(verts)
        let connector = VoronoiCornerConnector(voronoiPoint: self.voronoiPoint, boundaries: self.boundaries)
        verts += connector.connectToCorners(verts)
        self.vertices = verts
        return verts
    }
    
    /**
     Determines if the given vertices already form a complete loop.
     - parameter vertices: The vertices of the potential loop.
     - returns: true if the vertices already form a complete loop, false if not.
     */
    private func verticesAreComplete(vertices:[CGPoint]) -> Bool {
        guard let first = vertices.first, last = vertices.last where vertices.count > 1 else {
            return false
        }
        return first.liesOnAxisWith(last) && !(first ~= last)
    }

    /**
     Removes adjacent duplicate vertices. The way the algorithm works, duplicate
     vertices should always be adjacent to each other. This is most apparent when
     the voronoi points lie on a circle; then, many circle events will occur at the
     center of said circle, causing many duplicate points right next to each other.
     - parameter vertices: An array of points.
     - returns: The array of points with duplicate (and adjacent) vertices removed.
     */
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
     - returns: A tuple. The first element is true if the vertex loop has already been completed (whether the last
     point connects to the first point). The second element is the vertices of this side of the loop, in order.
     */
    private func seekToEndOfEdges(prev:VoronoiCellEdge, nextEdge:(edge:VoronoiCellEdge?, vertex:CGPoint)) -> (complete:Bool, points:[CGPoint]) {
        let frame = CGRect(size: self.boundaries)
        let first       = prev
        var vertices:[CGPoint] = []
        var previous    = prev
        var next        = nextEdge.edge
        var prevVertex  = nextEdge.vertex
        let boundaryVertices = prev.intersectionWith(self.boundaries)
        vertices += boundaryVertices
        if frame.contains(nextEdge.vertex) {
            vertices.append(nextEdge.vertex)
        }

        while let after = next {
            let successor = after.getNextFrom(previous)
            next = successor.edge
            previous = after
            
            if after === first {
                return (true, vertices)
            }
            
            //The reason we calculate an array of intersections is that
            //it's possible (usually for voronoi points near the corners of the diagram)
            //to have an edge that both starts and ends outside the diagram, in which
            //case there are 2 intersections with the boundaries we need to account for.
            if !frame.contains(after.startPoint) && frame.contains(after.endPoint) {
                for bv in after.intersectionWith(self.boundaries) {
                    vertices.append(bv)
                }
            } else if frame.contains(after.startPoint) && !frame.contains(after.endPoint) {
                for bv in after.intersectionWith(self.boundaries) {
                    vertices.append(bv)
                }
            } else if !frame.contains(after.startPoint) && !frame.contains(after.endPoint) {
                let intersections = after.intersectionWith(self.boundaries)
                for bv in intersections {
                    vertices.append(bv)
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
                return (false, vertices)
            }
            
            prevVertex = successor.vertex
        }
        return (false, vertices)
    }

}