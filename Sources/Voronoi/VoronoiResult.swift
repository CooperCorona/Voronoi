//
//  VoronoiResult.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

/**
 Enapsulates the result of a voronoi diagram.
 You can access the cells, edges, or individual vertices.
 */
public struct VoronoiResult {
    
    ///The cells. Each cell contains the original voronoi point
    ///and the points that form the edges around this specific cell.
    public let cells:[VoronoiCell]
    
    ///The edges of the entire diagram. Each element is a pair of
    ///points corresponding to an edge on the diagram. Note that
    ///some edges can start or end outside the diagram.
    public let edges:[(start:Point, end:Point)]
    
    ///The vertices of the edges of the diagram. Note
    ///that the vertices are obtained from the edges,
    ///so some lie outside the diagram.
    public let vertices:[Point]
    
    ///The boundaries of the voronoi diagram.
    public let boundaries:Size
    
    ///Used by VoronoiDiagram to store the result of Fortune's algorithm.
    ///You should not (and cannot) instantiate this yourself.
    internal init(cells:[VoronoiCell], edges:[VoronoiEdge], vertices:[Point], boundaries:Size) {
        self.cells = cells
        self.edges = edges.map() { (start: $0.startPoint, end: $0.endPoint) }
        self.vertices = vertices
        self.boundaries = boundaries
    }
    
    public func tile() -> VoronoiResult {
        var points:[Point] = []
        for cell in self.cells {
            points.append(cell.voronoiPoint)
            
            if cell.boundaryEdges.contains(.Right) && cell.boundaryEdges.contains(.Down) {
                points.append(cell.voronoiPoint + Point(x: -cell.boundaries.width, y: cell.boundaries.height))
            }
            if cell.boundaryEdges.contains(.Right) && cell.boundaryEdges.contains(.Up) {
                points.append(cell.voronoiPoint + Point(x: -cell.boundaries.width, y: -cell.boundaries.height))
            }
            if cell.boundaryEdges.contains(.Left) && cell.boundaryEdges.contains(.Down) {
                points.append(cell.voronoiPoint + Point(x: cell.boundaries.width, y: cell.boundaries.height))
            }
            if cell.boundaryEdges.contains(.Left) && cell.boundaryEdges.contains(.Up) {
                points.append(cell.voronoiPoint + Point(x: cell.boundaries.width, y: -cell.boundaries.height))
            }
            
            if cell.boundaryEdges.contains(.Right) {
                points.append(cell.voronoiPoint - Point(x: cell.boundaries.width, y: 0.0))
            }
            if cell.boundaryEdges.contains(.Left) {
                points.append(cell.voronoiPoint + Point(x: cell.boundaries.width, y: 0.0))
            }
            if cell.boundaryEdges.contains(.Up) {
                points.append(cell.voronoiPoint - Point(x: 0.0, y: cell.boundaries.height))
            }
            if cell.boundaryEdges.contains(.Down) {
                points.append(cell.voronoiPoint + Point(x: 0.0, y: cell.boundaries.height))
            }
        }
        return VoronoiDiagram(points: points, size: self.boundaries).sweep()
    }
}
