//
//  VoronoiCell.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 5/29/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

internal func ~=(lhs:Double, rhs:Double) -> Bool {
    let epsilon = 0.00001
    return abs(lhs - rhs) < epsilon
}

/**
 Combines a voronoi point and the edges / vertices around it.
 */
open class VoronoiCell {
    
    ///The original voronoi point.
    public let voronoiPoint:Point
    ///The boundaries of the VoronoiDiagram.
    public let boundaries:Size
    ///The vertices that form the edges of this cell.
    fileprivate var vertices:[Point]? = nil
    ///The actual edges that form the boundaries of this cell.
    internal var cellEdges:[VoronoiEdge] = []
    ///The neighboring cells adjacent to this cell.
    ///They must be weak references because otherwise, we have retain cycles.
    ///In a tiled diagram, this includes neighbors of symmetric cells (said
    ///symmetric cells do not have their own neighbors).
    internal var weakNeighbors:Set<WeakReference<VoronoiCell>> = []
    open var neighbors:[VoronoiCell] { return self.weakNeighbors.compactMap() { $0.object } }

    ///In a tiled diagram, cells outside the diagram are created. These are called the *symmetric* cells.
    ///In the interest of abstraction, these cells should not be considered on their own. Instead,
    ///they pass neighbors to their parent, so a cell can have a neighbor somewhere on the opposite
    ///side of the diagram because a symmetric child lies adjacent to it.
    internal weak var symmetricParent:VoronoiCell? = nil
    internal var symmetricChildren:[WeakReference<VoronoiCell>] = []
    ///In a tiled diagram, cells outside the diagram lying on the same axis as the original cells
    ///are created. These are called the *symmetric* cells. They are used to simulate laying a
    ///voronoi diagram side by side. These cells are not considered "real" by the result of the diagram.
    internal var isSymmetricCell:Bool { return self.symmetricParent == nil }
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
    public init(point:Point, boundaries:Size) {
        self.voronoiPoint   = point
        self.boundaries     = boundaries
    }

    ///Calculates the vertices in the correct order so they can be
    ///combined to form the edges of this cell.
    open func makeVertexLoop() -> [Point] {
        if let vertices = self.vertices {
            return vertices
        }
        let vertices = self.windVertices()
        self.vertices = vertices
        return vertices
    }
    
    fileprivate func insertBoundaryEdge(for intersection:Point) {
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
    fileprivate func windVertices() -> [Point] {
        let frame = Rect(origin: Point.zero, size: self.boundaries)
        var corners = [
            Point(x: 0.0, y: 0.0),
            Point(x: self.boundaries.width, y: 0.0),
            Point(x: self.boundaries.width, y: self.boundaries.height),
            Point(x: 0.0, y: self.boundaries.height),
        ]
        var vertices:[Point] = []
        for cellEdge in self.cellEdges {
            let line = VoronoiLine(start: cellEdge.startPoint, end: cellEdge.endPoint, voronoi: self.voronoiPoint)
            corners = corners.filter() { line.pointLiesAbove($0) == line.voronoiPointLiesAbove }

            let intersections = cellEdge.intersectionWith(self.boundaries)
            vertices += intersections
            if frame.contains(point: cellEdge.startPoint) {
                vertices.append(cellEdge.startPoint)
            }
            if frame.contains(point: cellEdge.endPoint) {
                vertices.append(cellEdge.endPoint)
            }
        }
        vertices += corners
        //The sorting approach only works if the voronoi point is inside
        //all the vertices, which isn't true if the voronoi point is
        //outside the bounds of the diagram. In that case, we need
        //to calculate a point inside all the vertices (in this case,
        //the geometric center). The algorithm proceeds the same,
        //it just doesn't require the potentially expensive operation.
        if frame.contains(point: self.voronoiPoint) {
            vertices = vertices.sorted() { self.voronoiPoint.angle(to: $0) < self.voronoiPoint.angle(to: $1) }
        } else {
            let center = vertices.reduce(Point.zero) { $0 + $1 } / Double(vertices.count)
            vertices = vertices.sorted() { center.angle(to: $0) < center.angle(to: $1) }
        }
        vertices = self.removeDuplicates(vertices)
        self._boundaryEdges = self.calculateBoundaryEdges(vertices: vertices)
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
    fileprivate func removeDuplicates(_ vertices:[Point]) -> [Point] {
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
     Determines which edges of the voronoi diagram this cell touches.
     - parameter vertices: The vertices of this cell.
     - returns: A set of directions corresponding to which edges of the boundaries this cell touches.
     */
    fileprivate func calculateBoundaryEdges(vertices:[Point]) -> Set<Direction2D> {
        var edges:Set<Direction2D> = []
        for vertex in vertices {
            if vertex.x ~= 0.0 {
                edges.insert(.Left)
            }
            if vertex.x ~= self.boundaries.width {
                edges.insert(.Right)
            }
            if vertex.y ~= 0.0 {
                edges.insert(.Down)
            }
            if vertex.y ~= self.boundaries.height {
                edges.insert(.Up)
            }
        }
        return edges
    }

    /**
     Adds a VoronoiCell as a neighbor to this cell.
     - parameter neighbor: The cell adjacent to this cell to mark as a neighbor.
     */
    internal func add(neighbor:VoronoiCell) {
        self.symmetricParent?.add(neighbor: neighbor)
        self.weakNeighbors.insert(WeakReference(object: neighbor))
    }

    internal func addSymmetricChild(x:Double, y:Double) -> VoronoiCell {
        let symmetricCell = VoronoiCell(point: self.voronoiPoint + Point(x: x, y: y), boundaries: self.boundaries)
        symmetricCell.symmetricParent = self
        self.symmetricChildren.append(WeakReference(object: symmetricCell))
        return symmetricCell
    }
    
}

extension VoronoiCell {
    
    public func contains(point:Point) -> Bool {
        //Ideally, the user has already called makeVertexLoop.
        //If not, we incur the expensive calculations (but
        //guarantee that the vertices exist).
        let vertices = self.makeVertexLoop()
        for (i, vertex) in vertices.enumerated().dropLast() {
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

extension VoronoiCell: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(Unmanaged.passUnretained(self).toOpaque())
    }

}

public func ==(lhs:VoronoiCell, rhs:VoronoiCell) -> Bool {
    return lhs === rhs
}
