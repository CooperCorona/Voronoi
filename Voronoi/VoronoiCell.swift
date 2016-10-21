//
//  VoronoiCell.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
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
 Combines a voronoi point and the edges / vertices around it.
 */
open class VoronoiCell {
    
    fileprivate enum TraversalResult {
        ///This is for when the start vertices need
        ///to be combined with the end vertices
        case deadEnd
        ///This is for when the vertices have
        ///already formed a loop.
        case completeLoop
        ///This is for when the vertices only
        ///need the corners to be added.
        case incompleteLoop
    }
    
    ///The original voronoi point.
    open let voronoiPoint:CGPoint
    ///The boundaries of the VoronoiDiagram.
    open let boundaries:CGSize
    ///The vertices that form the edges of this cell.
    fileprivate var vertices:[CGPoint]? = nil
    ///The actual edges that form the boundaries of this cell.
    internal var cellEdges:Set<VoronoiCellEdge> = []
    
    internal var log:Bool { return self.voronoiPoint.x ~= 200.0 && self.voronoiPoint.y ~= 100.0 }
    internal var walkedAllEdges:Bool {
        return self.cellEdges.reduce(true) { $0 && $1.walked }
    }
    
    ///Initializes a VoronoiCell with a voronoi point and the boundaries of a VoronoiDiagram.
    public init(point:CGPoint, boundaries:CGSize) {
        self.voronoiPoint   = point
        self.boundaries     = boundaries
    }

    ///Calculates the vertices in the correct order so they can be
    ///combined to form the edges of this cell.
    open func makeVertexLoop() -> [CGPoint] {
        if let vertices = self.vertices {
            return vertices
        }
        guard let start = self.cellEdges.first else {
            return []
        }
        
        if self.log {
            for ce in self.cellEdges {
                print("\(ce.startPointString) -> \(ce.endPointString)")
            }
        }

        let (complete, startVertices) = self.seekToEndOfEdges(start, nextEdge: (start.startNeighbor, start.startPoint))
        //Inner cell, we already have a loop.
        if complete == .completeLoop || self.verticesAreComplete(startVertices) {
            return startVertices
        }
        
        var verts:[CGPoint] = startVertices.reversed()
//        var verts:[CGPoint] = []

        if complete == .deadEnd {
            let (_, endVertices) = self.seekToEndOfEdges(start, nextEdge: (start.endNeighbor, start.endPoint))
            //If the start vertices already connect edges, we don't want
            //to calculate the end vertices because that introduces duplicates
            //that are not necessarily adjacent, so they won't be caught by removeDuplicates.
            if self.verticesAreOnOppositeEdges(startVertices) {
                //Often walking the start vertices fails because it adds the initial
                //point and then stops. Walking the end vertices causes there to be
                //some set of points P -> Q -> P in the vertex array. This duplication
                //of P is incorrect. We solve this by entirely ignoring the initial vertex.
                verts = endVertices
            } else {
                verts += endVertices
            }
//            verts = self.connect(array: startVertices, to: endVertices)
//            verts += endVertices
        } else {
//            verts = startVertices.reversed()
        }/* else if self.cellEdges.count == 2 && (start.directionVector.x ~= 0.0 || start.directionVector.y ~= 0.0) {
            //In this case, the cell has edges that are either perfectly horizontal
            //or perfectly vertical. Also, the edges must touch both boundaries because
            //otherwise there would not be 2 of them. Thus, the cell walking algorithm fails, because
            //the edges aren't connected. In this case, we manually walk the edges of the other edge.
            if let last = self.cellEdges.last {
                let (_, startVertices) = self.seekToEndOfEdges(last, nextEdge: (last.startNeighbor, last.startPoint))
                //A perfectly vertical line that connects with no others will either
                //begin walking at the start point and stop at the end point or begin
                //at the end point and stop at the start point. Either way produces
                //the correct diagram.
                verts += startVertices
            }
        }*/
        if let nonConnectedEdge = self.cellEdges.first, !self.walkedAllEdges {
            var (_, nonConnectedVerts) = self.seekToEndOfEdges(nonConnectedEdge, nextEdge: (nonConnectedEdge.endNeighbor, nonConnectedEdge.endPoint))
            nonConnectedVerts.reverse()
            var (_, endNonConnectedVerts) = self.seekToEndOfEdges(nonConnectedEdge, nextEdge: (nonConnectedEdge.startNeighbor, nonConnectedEdge.startPoint))
            if self.verticesAreOnOppositeEdges(nonConnectedVerts) {
                nonConnectedVerts = endNonConnectedVerts
            } else {
                nonConnectedVerts += endNonConnectedVerts
            }
            verts = self.connect(array: verts, to: nonConnectedVerts)
            /*
            if let firstVert = verts.first, let lastVert = nonConnectedVerts.last, firstVert.x ~= lastVert.x || firstVert.y ~= lastVert.y {
                verts += nonConnectedVerts
            } else {
                verts += nonConnectedVerts.reversed()
            }
            */
            if log {
//                print(verts)
            }
        }
        verts = self.removeDuplicates(verts)
        let connector = VoronoiCornerConnector(voronoiPoint: self.voronoiPoint, boundaries: self.boundaries)
        let corners = connector.connectToCorners(verts)
        
        verts += corners
        self.vertices = verts
        print("\(self.voronoiPoint): \(self.vertices)")
        return verts
    }
    
    fileprivate func connect(array:[CGPoint], to:[CGPoint]) -> [CGPoint] {
        //If the first or the second doesn't exist, then the array
        //is empty. The other array might be empty, but it might not,
        //so we return it.
        guard let last = array.last else {
            return to
        }
        guard let first = to.first else {
            return array
        }
        if first.x ~= last.x || first.y ~= last.y {
            return array + to
        } else {
            return array.reversed() + to
        }
    }
    
    /**
     Determines if the given vertices already form a complete loop.
     - parameter vertices: The vertices of the potential loop.
     - returns: true if the vertices already form a complete loop, false if not.
     */
    fileprivate func verticesAreComplete(_ vertices:[CGPoint]) -> Bool {
        guard let first = vertices.first, let last = vertices.last , vertices.count > 1 else {
            return false
        }
        if first.x ~= 0.0 && last.x ~= 0.0 {
            return true
        } else if first.x ~= self.boundaries.width && last.x ~= self.boundaries.width {
            return true
        } else  if first.y ~= 0.0 && last.y ~= 0.0 {
            return true
        } else if first.y ~= self.boundaries.height && last.y ~= self.boundaries.height {
            return true
        }
        return false
    }
    
    /**
     Determines if the given vertices already touch separate edges (if the
     vertices touch edges after walking the start vertices, there
     is no point in walking the end vertices; in fact, it's actively harmful).
     - parameter vertices: The vertices to check if the first and last elements
     both lie on edges.
     - returns: true if the vertices already touch separate edges, false otherwise
     */
    fileprivate func verticesAreOnOppositeEdges(_ vertices:[CGPoint]) -> Bool {
        guard let first = vertices.first, let last = vertices.last , vertices.count >= 1 else {
            return false
        }
        let firstXAxis = first.x ~= 0.0 || first.x ~= self.boundaries.width
        let firstYAxis = first.y ~= 0.0 || first.y ~= self.boundaries.height
        let lastXAxis = last.x ~= 0.0 || last.x ~= self.boundaries.width
        let lastYAxis = last.y ~= 0.0 || last.y ~= self.boundaries.height
        return (firstXAxis && lastXAxis) || (firstYAxis && lastYAxis)
        //return self.pointIsOnEdge(first) && self.pointIsOnEdge(last)
    }
    
    fileprivate func pointIsOnEdge(_ point:CGPoint) -> Bool {
        return point.x ~= 0.0 || point.x ~= self.boundaries.width || point.y ~= 0.0 || point.y ~= self.boundaries.height
    }

    /**
     Removes adjacent duplicate vertices. The way the algorithm works, duplicate
     vertices should always be adjacent to each other. This is most apparent when
     the voronoi points lie on a circle; then, many circle events will occur at the
     center of said circle, causing many duplicate points right next to each other.
     - parameter vertices: An array of points.
     - returns: The array of points with duplicate (and adjacent) vertices removed.
     */
    fileprivate func removeDuplicates(_ vertices:[CGPoint]) -> [CGPoint] {
        var i = 0
        var filteredVertices = vertices
        while i < filteredVertices.count - 1 {
            if filteredVertices[i] ~= filteredVertices[i + 1] {
                filteredVertices.remove(at: i + 1)
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
    fileprivate func seekToEndOfEdges(_ prev:VoronoiCellEdge, nextEdge:(edge:VoronoiCellEdge?, vertex:CGPoint)) -> (complete:TraversalResult, points:[CGPoint]) {
        prev.walked = true
        self.cellEdges.remove(prev)
        
        var edgeValidator = VoronoiDiagramEdgeValidator(boundaries: self.boundaries)
        
        let frame = CGRect(size: self.boundaries)
        let first       = prev
        var vertices:[CGPoint] = []
        var previous    = prev
        var next        = nextEdge.edge
        var prevVertex  = nextEdge.vertex
        let boundaryVertices = prev.intersectionWith(self.boundaries)
        vertices += prev.sort(intersections: boundaryVertices, byStart: prev.opposite(vertex: nextEdge.vertex))
        if (frame.contains(nextEdge.vertex)) && !vertices.contains(where: { $0 ~= nextEdge.vertex }) {
            vertices.append(nextEdge.vertex)
        }
        //We're not actually going to restrict added points here,
        //we just need to initialize the edge validator with the
        //points and edges that already exist.
        for v in vertices {
            edgeValidator.validatePoint(v)
        }

        while let after = next {
            after.walked = true
            self.cellEdges.remove(after)
            let successor = after.getNextFrom(previous)
            next = successor.edge
            previous = after

            
            if after === first {
                return (edgeValidator.validatePoint(successor.vertex) ? .incompleteLoop : .completeLoop, vertices)
            }
            
            //The reason we calculate an array of intersections is that
            //it's possible (usually for voronoi points near the corners of the diagram)
            //to have an edge that both starts and ends outside the diagram, in which
            //case there are 2 intersections with the boundaries we need to account for.
            //The last else-if statement is the only case in which there will by multiple
            //elements in the array, though. The first two are guaranteed to have < 2.
            if !(frame.contains(after.startPoint)) && (frame.contains(after.endPoint)) {
                for bv in after.intersectionWith(self.boundaries) {
                    if edgeValidator.validatePoint(bv) {
                        vertices.append(bv)
                    } else {
                        return (.deadEnd, vertices)
                    }
                }
            } else if (frame.contains(after.startPoint)) && !(frame.contains(after.endPoint)) {
                for bv in after.intersectionWith(self.boundaries) {
                    if edgeValidator.validatePoint(bv) {
                        vertices.append(bv)
                    } else {
                        return (.deadEnd, vertices)
                    }
                }
            } else if !(frame.contains(after.startPoint)) && !(frame.contains(after.endPoint)) {
                let intersections = after.intersectionWith(self.boundaries)
                let sortedIntersections = after.sort(intersections: intersections, byStart: prevVertex)
                for bv in sortedIntersections {
                    vertices.append(bv)
                }
            }
            
            if !edgeValidator.validatePoint(successor.vertex) {
                return (.deadEnd, vertices)
            }
            
            if frame.contains(successor.vertex) {
                vertices.append(successor.vertex)
            }
            
            prevVertex = successor.vertex
        }
        return (.deadEnd, vertices)
    }

}
