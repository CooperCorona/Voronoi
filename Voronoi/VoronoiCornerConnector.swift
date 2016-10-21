//
//  VoronoiCornerConnector.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/10/16.
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
 Exposes methods that connect the ends of a cell's array of vertices
 to the necessary corners to complete the loop.
 */
internal struct VoronoiCornerConnector {
    
    internal enum Corner {
        case bottomLeft
        case bottomRight
        case topLeft
        case topRight
        
        internal static let allElements = [
            Corner.bottomLeft,
            Corner.bottomRight,
            Corner.topRight,
            Corner.topLeft
        ]
        
        ///Gets the coordinates of self in a given rectangle (represented by size).
        internal func get(_ boundaries:CGSize) -> CGPoint {
            switch self {
            case .bottomLeft:
                return CGPoint.zero
            case .bottomRight:
                return CGPoint(x: boundaries.width)
            case .topRight:
                return CGPoint(x: boundaries.width, y: boundaries.height)
            case .topLeft:
                return CGPoint(y: boundaries.height)
            }
        }
        
        ///Gets the next corner in the clockwise direction.
        internal func nextClockwise() -> Corner {
            switch self {
            case .bottomLeft:
                return .topLeft
            case .bottomRight:
                return .bottomLeft
            case .topRight:
                return .bottomRight
            case .topLeft:
                return .topRight
            }
        }
        
        ///Gets the next corner in the counterclockwise direction.
        internal func nextCounterClockwise() -> Corner {
            switch self {
            case .topLeft:
                return .bottomLeft
            case .bottomLeft:
                return .bottomRight
            case .bottomRight:
                return .topRight
            case .topRight:
                return .topLeft
            }
        }
    }
    
    ///The voronoi point associated with the cell you're connecting to the corners.
    internal let voronoiPoint:CGPoint
    ///The boundaries of the voronoi diagram.
    internal let boundaries:CGSize
    
    internal init(voronoiPoint:CGPoint, boundaries:CGSize) {
        self.voronoiPoint = voronoiPoint
        self.boundaries = boundaries
    }

    /**
     Connects an array of vertices to the necessary corners of the voronoi
     diagram's boundaries to complete the loop.
     - parameter vertices: The current vertices of the cell you're connecting.
     - returns: The coordinates of the corner that, when added to the end of
     */
    internal func connectToCorners(_ vertices:[CGPoint]) -> [CGPoint] {
        guard let first = vertices.first, let second = vertices.objectAtIndex(1), let nextToLast = vertices.objectAtIndex(vertices.count - 2), let last = vertices.last else {
            return []
        }
        
        let startLine = VoronoiLine(start: second, end: first, voronoi: self.voronoiPoint)
        let endLine = VoronoiLine(start: nextToLast, end: last, voronoi: self.voronoiPoint)
        
        let validCorners = Corner.allElements.filter() {
            let cornerPoint = $0.get(self.boundaries)
            return startLine.pointLiesAbove(cornerPoint) == startLine.voronoiPointLiesAbove &&
                endLine.pointLiesAbove(cornerPoint) == endLine.voronoiPointLiesAbove &&
                !(cornerPoint ~= first || cornerPoint ~= last)
        }
        
        if last.x ~= 0.0 {
            if validCorners.contains(.bottomLeft) {
                return self.walkCorners(validCorners, startingAt: .bottomLeft, clockwise: false)
            } else if validCorners.contains(.topLeft) {
                return self.walkCorners(validCorners, startingAt: .topLeft, clockwise: true)
            }
        } else if last.x ~= self.boundaries.width {
            if validCorners.contains(.bottomRight) {
                return self.walkCorners(validCorners, startingAt: .bottomRight, clockwise: true)
            } else if validCorners.contains(.topRight) {
                return self.walkCorners(validCorners, startingAt: .topRight, clockwise: false)
            }
        }
        if last.y ~= 0.0 {
            if validCorners.contains(.bottomLeft) {
                return self.walkCorners(validCorners, startingAt: .bottomLeft, clockwise: true)
            } else if validCorners.contains(.bottomRight) {
                return self.walkCorners(validCorners, startingAt: .bottomRight, clockwise: false)
            }
        } else if last.y ~= self.boundaries.height {
            if validCorners.contains(.topLeft) {
                return self.walkCorners(validCorners, startingAt: .topLeft, clockwise: false)
            } else if validCorners.contains(.topRight) {
                return self.walkCorners(validCorners, startingAt: .topRight, clockwise: true)
            }
        }
        return []
    }
    
    /**
     Moves along the corners of the rectangle until reaching an invalid corner, connecting
     the vertices.
     - parameter validCorners: The corners that are valid to be connected with this cell.
     - parameter startCorner: The first corner to connect to.
     - parameter clockwise: True to move in a clockwise direction, false for counterclockwise.
     - returns: Coordinates corresponding to the corners that, when connected to, complete the vertex loop.
     */
    fileprivate func walkCorners(_ validCorners:[Corner], startingAt startCorner:Corner, clockwise:Bool) -> [CGPoint] {
        var corner = startCorner
        var corners:[Corner] = []
        while validCorners.contains(corner) {
            corners.append(corner)
            if clockwise {
                corner = corner.nextClockwise()
            } else {
                corner = corner.nextCounterClockwise()
            }
        }
        return corners.map() { $0.get(self.boundaries) }
    }

}
