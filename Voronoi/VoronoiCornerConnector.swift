//
//  VoronoiCornerConnector.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/10/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import CoronaConvenience
import CoronaStructures
import CoronaGL

/**
 Exposes methods that connect the ends of a cell's array of vertices
 to the necessary corners to complete the loop.
 */
internal struct VoronoiCornerConnector {
    
    internal enum Corner {
        case BottomLeft
        case BottomRight
        case TopLeft
        case TopRight
        
        internal static let allElements = [
            Corner.BottomLeft,
            Corner.BottomRight,
            Corner.TopRight,
            Corner.TopLeft
        ]
        
        ///Gets the coordinates of self in a given rectangle (represented by size).
        internal func get(boundaries:CGSize) -> CGPoint {
            switch self {
            case .BottomLeft:
                return CGPoint.zero
            case .BottomRight:
                return CGPoint(x: boundaries.width)
            case .TopRight:
                return CGPoint(x: boundaries.width, y: boundaries.height)
            case .TopLeft:
                return CGPoint(y: boundaries.height)
            }
        }
        
        ///Gets the next corner in the clockwise direction.
        internal func nextClockwise() -> Corner {
            switch self {
            case .BottomLeft:
                return .TopLeft
            case .BottomRight:
                return .BottomLeft
            case .TopRight:
                return .BottomRight
            case .TopLeft:
                return .TopRight
            }
        }
        
        ///Gets the next corner in the counterclockwise direction.
        internal func nextCounterClockwise() -> Corner {
            switch self {
            case .TopLeft:
                return .BottomLeft
            case .BottomLeft:
                return .BottomRight
            case .BottomRight:
                return .TopRight
            case .TopRight:
                return .TopLeft
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
    internal func connectToCorners(vertices:[CGPoint]) -> [CGPoint] {
        guard let first = vertices.first, second = vertices.objectAtIndex(1), nextToLast = vertices.objectAtIndex(vertices.count - 2), last = vertices.last else {
            return []
        }
        
        let startLine = VoronoiLine(start: second, end: first, voronoi: self.voronoiPoint)
        let endLine = VoronoiLine(start: nextToLast, end: last, voronoi: self.voronoiPoint)
        
        let validCorners = Corner.allElements.filter() {
            startLine.pointLiesAbove($0.get(self.boundaries)) == startLine.voronoiPointLiesAbove &&
                endLine.pointLiesAbove($0.get(self.boundaries)) == endLine.voronoiPointLiesAbove
        }
        
        if last.x ~= 0.0 {
            if validCorners.contains(.BottomLeft) {
                return self.walkCorners(validCorners, startingAt: .BottomLeft, clockwise: false)
            } else if validCorners.contains(.TopLeft) {
                return self.walkCorners(validCorners, startingAt: .TopLeft, clockwise: true)
            }
        } else if last.x ~= self.boundaries.width {
            if validCorners.contains(.BottomRight) {
                return self.walkCorners(validCorners, startingAt: .BottomRight, clockwise: true)
            } else if validCorners.contains(.TopRight) {
                return self.walkCorners(validCorners, startingAt: .TopRight, clockwise: false)
            }
        } else if last.y ~= 0.0 {
            if validCorners.contains(.BottomLeft) {
                return self.walkCorners(validCorners, startingAt: .BottomLeft, clockwise: true)
            } else if validCorners.contains(.BottomRight) {
                return self.walkCorners(validCorners, startingAt: .BottomRight, clockwise: false)
            }
        } else if last.y ~= self.boundaries.height {
            if validCorners.contains(.TopLeft) {
                return self.walkCorners(validCorners, startingAt: .TopLeft, clockwise: false)
            } else if validCorners.contains(.TopRight) {
                return self.walkCorners(validCorners, startingAt: .TopRight, clockwise: true)
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
    private func walkCorners(validCorners:[Corner], startingAt startCorner:Corner, clockwise:Bool) -> [CGPoint] {
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