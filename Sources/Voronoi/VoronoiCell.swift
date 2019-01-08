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
    
    ///The original voronoi point.
    open let voronoiPoint:CGPoint
    ///The boundaries of the VoronoiDiagram.
    open let boundaries:CGSize
    ///The vertices that form the edges of this cell.
    fileprivate var vertices:[CGPoint]? = nil
    ///The actual edges that form the boundaries of this cell.
    internal var cellEdges:[VoronoiEdge] = []
    ///The neighboring cells adjacent to this cell.
    ///They must be weak references because otherwise, we have retain cycles.
    internal var weakNeighbors:[WeakReference<VoronoiCell>] = []
    open var neighbors:[VoronoiCell] { return self.weakNeighbors.flatMap() { $0.object } }
    
    ///The set of the voronoi diagram's boundaries that this
    ///cell touches. Initialized by makeVertexLoop.
    private var _boundaryEdges:Set<Direction2D> = []
    open private(set) lazy var boundaryEdges:Set<Direction2D> = {
        //We can't initialize boundaryEdges until makeVertexLoop
        //is called, but we can't use normal lazy loading because
        //makeVertexLoop initializes it directly. Thus, we have
        //a private variable that makeVertexLoop initializes.
        //Then, this public variable just sets itself to the
        //value of the private variable, first making sure
        //the private variable is initialized.
        let _ = self.makeVertexLoop()
        return self._boundaryEdges
    }()
    
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
        let vertices = self.windVertices()
        self.vertices = vertices
        return vertices
    }
    
    fileprivate func insertBoundaryEdge(for intersection:CGPoint) {
        if intersection.x ~= 0.0 {
            self._boundaryEdges.insert(.Left)
        }
        if intersection.x ~= self.boundaries.width {
            self._boundaryEdges.insert(.Right)
        }
        if intersection.y ~= 0.0 {
            self._boundaryEdges.insert(.Down)
        }
        if intersection.y ~= self.boundaries.height {
            self._boundaryEdges.insert(.Up)
        }
    }
    
    /**
     Generates all the vertices associated with this cell,
     and then sorts them according to their angle from the
     voronoi point.
    */
    fileprivate func windVertices() -> [CGPoint] {
        let frame = CGRect(size: self.boundaries)
        var corners = [
            CGPoint(x: 0.0, y: 0.0),
            CGPoint(x: self.boundaries.width, y: 0.0),
            CGPoint(x: self.boundaries.width, y: self.boundaries.height),
            CGPoint(x: 0.0, y: self.boundaries.height),
        ]
        var vertices:[CGPoint] = []
        for cellEdge in self.cellEdges {
            let line = VoronoiLine(start: cellEdge.startPoint, end: cellEdge.endPoint, voronoi: self.voronoiPoint)
            corners = corners.filter() { line.pointLiesAbove($0) == line.voronoiPointLiesAbove }
            
            let intersections = cellEdge.intersectionWith(self.boundaries)
            vertices += intersections
            for intersection in intersections {
                self.insertBoundaryEdge(for: intersection)
            }
            
            if frame.contains(cellEdge.startPoint) {
                vertices.append(cellEdge.startPoint)
                self.insertBoundaryEdge(for: cellEdge.startPoint)
            }
            if frame.contains(cellEdge.endPoint) {
                vertices.append(cellEdge.endPoint)
                self.insertBoundaryEdge(for: cellEdge.endPoint)
            }
        }
        vertices += corners
        //The sorting approach only works if the voronoi point is inside
        //all the vertices, which isn't true if the voronoi point is
        //outside the bounds of the diagram. In that case, we need
        //to calculate a point inside all the vertices (in this case,
        //the geometric center). The algorithm proceeds the same,
        //it just doesn't require the potentially expensive operation.
        if frame.contains(self.voronoiPoint) {
            vertices = vertices.sorted() { self.voronoiPoint.angleTo($0) < self.voronoiPoint.angleTo($1) }
        } else {
            let center = vertices.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(vertices.count)
            vertices = vertices.sorted() { center.angleTo($0) < center.angleTo($1) }
        }
        vertices = self.removeDuplicates(vertices)
        return vertices
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
     Adds a VoronoiCell as a neighbor to this cell.
     - parameter neighbor: The cell adjacent to this cell to mark as a neighbor.
     */
    internal func add(neighbor:VoronoiCell) {
        self.weakNeighbors.append(WeakReference(object: neighbor))
    }
    
}

extension VoronoiCell {
    
    public func contains(point:CGPoint) -> Bool {
        //Ideally, the user has already called makeVertexLoop.
        //If not, we incur the expensive calculations (but
        //guarantee that the vertices exist).
        let vertices = self.makeVertexLoop()
        for (i, vertex) in vertices.enumerateSkipLast() {
            let line = VoronoiLine(start: vertex, end: vertices[i + 1], voronoi: self.voronoiPoint)
            if line.pointLiesAbove(point) != line.voronoiPointLiesAbove {
                return false
            }
        }
        if let last = vertices.last, let first = vertices.first {
            let lastLine = VoronoiLine(start: last, end: first, voronoi: self.voronoiPoint)
            if lastLine.pointLiesAbove(point) != lastLine.voronoiPointLiesAbove {
                return false
            }
        }
        return true
    }
    
}
