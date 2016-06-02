//
//  VoronoiResult.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit

//TODO: Make edges contain only points lying in the diagram.
//TODO: Make vertices contain only points lying in the diagram.

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
    public let edges:[(start:CGPoint, end:CGPoint)]
    
    ///The vertices of the edges of the diagram. Note that not all
    ///edges are guaranteed to lie inside the diagram. Note that
    ///the vertices are obtained from the edges, so some vertices
    ///lie outside the diagram.
    public let vertices:[CGPoint]
    
    ///Used by VoronoiDiagram to store the result of Fortune's algorithm.
    ///You should not (and cannot) instantiate this yourself.
    internal init(cells:[VoronoiCell], edges:[VoronoiEdge], vertices:[CGPoint]) {
        self.cells = cells
        self.edges = edges.map() { (start: $0.startPoint, end: $0.endPoint) }
        self.vertices = vertices
    }
    
}