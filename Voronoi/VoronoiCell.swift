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
    
    fileprivate func windVertices() -> [CGPoint] {
        let frame = CGRect(size: self.boundaries)
        var corners = VoronoiCornerConnector.Corner.allElements.map() { $0.get(self.boundaries) }
        var vertices:[CGPoint] = []
        for cellEdge in self.cellEdges {
            let line = VoronoiLine(start: cellEdge.startPoint, end: cellEdge.endPoint, voronoi: self.voronoiPoint)
            corners = corners.filter() { line.pointLiesAbove($0) == line.voronoiPointLiesAbove }
            vertices += cellEdge.intersectionWith(self.boundaries)
            if frame.contains(cellEdge.startPoint) {
                vertices.append(cellEdge.startPoint)
            }
            if frame.contains(cellEdge.endPoint) {
                vertices.append(cellEdge.endPoint)
            }
        }
        vertices += corners
        vertices = vertices.sorted() { self.voronoiPoint.angleTo($0) < self.voronoiPoint.angleTo($1) }
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

}
