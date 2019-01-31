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
        self.cells = cells.filter() { !$0.isSymmetricCell }
        self.edges = edges.map() { (start: $0.startPoint, end: $0.endPoint) }
        self.vertices = vertices
        self.boundaries = boundaries
    }
    
    public func tile() -> VoronoiResult {
        var cells:[VoronoiCell] = []
        for cell in self.cells {
            let newCell = VoronoiCell(point: cell.voronoiPoint, boundaries: cell.boundaries)
            cells.append(newCell)

            if cell.boundaryEdges.contains(.Right) && cell.boundaryEdges.contains(.Down) {
                let symmetricChild = newCell.addSymmetricChild(x: -cell.boundaries.width, y: cell.boundaries.height)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Right) && cell.boundaryEdges.contains(.Up) {
                let symmetricChild = newCell.addSymmetricChild(x: -cell.boundaries.width, y: -cell.boundaries.height)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Left) && cell.boundaryEdges.contains(.Down) {
                let symmetricChild = newCell.addSymmetricChild(x: cell.boundaries.width, y: cell.boundaries.height)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Left) && cell.boundaryEdges.contains(.Up) {
                let symmetricChild = newCell.addSymmetricChild(x: cell.boundaries.width, y: -cell.boundaries.height)
                cells.append(symmetricChild)
            }
            
            if cell.boundaryEdges.contains(.Right) {
                let symmetricChild = newCell.addSymmetricChild(x: -cell.boundaries.width, y: 0.0)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Left) {
                let symmetricChild = newCell.addSymmetricChild(x: cell.boundaries.width, y: 0.0)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Up) {
                let symmetricChild = newCell.addSymmetricChild(x: 0.0, y: -cell.boundaries.height)
                cells.append(symmetricChild)
            }
            if cell.boundaryEdges.contains(.Down) {
                let symmetricChild = newCell.addSymmetricChild(x: 0.0, y: cell.boundaries.height)
                cells.append(symmetricChild)
            }
        }
        return VoronoiDiagram(cells: cells, size: self.boundaries).sweep()
    }

    public func colors<R: RandomNumberGenerator>(count:Int, using random:R? = nil) -> ColorAssignment<VoronoiCell> {
        let graph = ColorGraph<VoronoiCell>()
        for cell in self.cells {
            graph.add(node: cell)
        }
        for cell in self.cells {
            for neighbor in cell.neighbors {
                try! graph.addEdge(from: cell, to: neighbor)
            }
        }
        return graph.colorGraph(count: count, using: random)
    }
}
