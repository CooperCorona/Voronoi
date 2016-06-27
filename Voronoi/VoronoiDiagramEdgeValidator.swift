//
//  VoronoiDiagramEdgeValidator.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/26/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import OmniSwift

/**
 Handles cases where portions of edges of a VoronoiCell lie
 outside the VoronoiDiagram. In some cases, the VoronoiCell
 should stop traversing the edges, but in some cases, it
 shoudl continue.
 */
internal struct VoronoiDiagramEdgeValidator {
    
    internal struct Edge: OptionSetType {
        
        internal let rawValue:Int
        
        internal init(rawValue:Int) {
            self.rawValue = rawValue
        }
        
        static let None             = Edge(rawValue: 0b0000)
        static let All              = Edge(rawValue: 0b1111)

        static let Right            = Edge(rawValue: 0b0001)
        static let AllButRight      = Edge(rawValue: 0b1110)
        
        static let Top              = Edge(rawValue: 0b0010)
        static let AllButTop        = Edge(rawValue: 0b1101)
        
        static let Left             = Edge(rawValue: 0b0100)
        static let AllButLeft       = Edge(rawValue: 0b1011)
        
        static let Bottom           = Edge(rawValue: 0b1000)
        static let AllButBottom     = Edge(rawValue: 0b0111)
    }
    
    internal let boundaries:CGSize
    private var touchedEdges = Edge.None
    private var previousPoint:CGPoint? = nil
    
    internal init(boundaries:CGSize) {
        self.boundaries = boundaries
        print("**********")
    }
    
    /**
     Determines if the set of touched edges
     intersects the given edge (normally I would
     call the .contains method on OptionSetType,
     but I want to consider any intersection valid,
     not a total intersection. That is, Edge.All.contains(Edge.right)
     is false, because the intersection of Edge.All and
     Edge.right is not equal to Edge.All, but I want to
     consider that true.
     */
    private func contains(edge:Edge) -> Bool {
        return (self.touchedEdges.rawValue & edge.rawValue) != 0
    }
    
    private func containsPoint(point:CGPoint) -> Bool {
        return 0.0 <= point.x && point.x <= self.boundaries.width
            && 0.0 <= point.y && point.y <= self.boundaries.height
    }
    
    private func pointIsOnEdge(point:CGPoint) -> Bool {
        return point.x ~= 0.0 || point.x ~= self.boundaries.width || point.y ~= 0.0 || point.y ~= self.boundaries.height
    }
    
    private func previousPointLiedInBoundaries() -> Bool {
        guard let previousPoint = self.previousPoint else {
            return true
        }
        return self.containsPoint(previousPoint)
    }

    /**
     Determines if a points should be added to the
     traversed vertices. If the traversed vertices
     have already crossed the boundaries of the VoronoiDiagram,
     and they are crossing again, we have two cases. If the
     edges are crossing the same boundary as before, we want
     to continue traversing. If the edges are crossing a new
     boundary, that means we will have skipped a corner, so
     we do not add the vertex.
     */
    internal mutating func validatePoint(point:CGPoint) -> Bool {
        
        if self.previousPointLiedInBoundaries() && self.containsPoint(point) {
            self.reset()
        }
        
        //We have to account for the case in which
        //a point lies exactly on a corner (and thus
        //lies on two edges)
        let previousTouchedEdges = self.touchedEdges
        var shouldAdd = true
        if point.x ~= 0.0 {
            if !self.contains(.Left) && self.contains(.AllButLeft) {
                shouldAdd = false
            }
            self.touchedEdges.unionInPlace(.Left)
        } else if point.x ~= self.boundaries.width {
            if !self.contains(.Right) && self.contains(.AllButRight) {
                shouldAdd = false
            }
            self.touchedEdges.unionInPlace(.Right)
        }
        
        if point.y ~= 0.0 {
            if !self.contains(.Bottom) && self.contains(.AllButBottom) {
                shouldAdd = false
            }
            self.touchedEdges.unionInPlace(.Bottom)
        } else if point.y ~= self.boundaries.height {
            if !self.contains(.Top) && self.contains(.AllButTop) {
                shouldAdd = false
            }
            self.touchedEdges.unionInPlace(.Top)
        }
        
        let liedInBoundaries = self.previousPointLiedInBoundaries()
        /*if self.boundariesRect.contains(point) && !liedInBoundaries {
            //If the edges have not changed but the point is valid,
            //that means we're adding a point on the same edge, so we
            //should reset so we don't interfere with exits on other boundaries.
            self.reset()
        }*/
        self.previousPoint = point
        print("Point: \(point.clampDecimals(1))")
        return shouldAdd// || liedInBoundaries
    }
    
    internal mutating func reset() {
        self.touchedEdges = Edge.None
    }
    
}