//
//  VoronoiCornerConnector.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/10/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import OmniSwift

internal struct Line {
    internal var startPoint:CGPoint
    internal var endPoint:CGPoint
    
    internal var directionVector:CGPoint { return (self.endPoint - self.startPoint).unit() }
    ///The slope of the line that this edge lies on.
    internal var slope:CGFloat {
        //Negative recipricol to get the actual slope perpendicular to the focii.
        return (self.endPoint.y - self.startPoint.y) / (self.endPoint.x - self.startPoint.x)
    }
    ///The y-intercept of the line that this edge lies on.
    internal var yIntercept:CGFloat {
        return self.startPoint.y - self.slope * self.startPoint.x
    }
    internal var isVertical:Bool { return self.directionVector.x ~= 0.0 }
    internal private(set) var voronoiPointLiesAbove:Bool = false
    
    internal init(start:CGPoint, end:CGPoint, voronoi:CGPoint) {
        self.startPoint = start
        self.endPoint = end
        self.voronoiPointLiesAbove = self.pointLiesAbove(voronoi)
    }
    
    internal func pointLiesAbove(point:CGPoint) -> Bool {
        if self.isVertical {
            return point.x < self.startPoint.x
        } else {
            return point.y - self.slope * point.x > self.yIntercept
        }
    }
    
}

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
    
    internal let voronoiPoint:CGPoint
    internal let boundaries:CGSize
    private var usedCorners:[Corner] = []
    
    internal init(voronoiPoint:CGPoint, boundaries:CGSize) {
        self.voronoiPoint = voronoiPoint
        self.boundaries = boundaries
    }
    
    internal mutating func connectFirst(first:CGPoint, toLast lastPoint:CGPoint, startLine:VoronoiCellEdge, endLine:VoronoiCellEdge) -> [CGPoint] {
        guard !(first.x ~= 0.0 && lastPoint.x ~= 0.0) else {
            return []
        }
        guard !(first.x ~= self.boundaries.width && lastPoint.x ~= self.boundaries.width) else {
            return []
        }
        guard !(first.y ~= 0.0 && lastPoint.y ~= 0.0) else {
            return []
        }
        guard !(first.y ~= self.boundaries.height && lastPoint.y ~= self.boundaries.height) else {
            return []
        }
        
        //Parallel (or potentially the same lines).
        if startLine.slope ~= endLine.slope {
            //If the slope of a line is greater than 0, then a point above
            //the line is also to its left. If the slope is less than 0,
            //then a point below the line is to its left.
            if startLine.slope > 0.0 {
                self.point(self.voronoiPoint, liesAbove: startLine)
            } else {
                !self.point(self.voronoiPoint, liesAbove: startLine)
            }
            switch (startLine.slope > 0.0, self.point(self.voronoiPoint, liesAbove: startLine)) {
            case (true, true):
                self.usedCorners.append(.BottomRight)
            case (true, false):
                self.usedCorners.append(.TopLeft)
            case (false, true):
                self.usedCorners.append(.BottomLeft)
            case (false, false):
                self.usedCorners.append(.TopRight)
            }
        } else {
            let x = (endLine.yIntercept - startLine.yIntercept) / (startLine.slope - endLine.slope)
            let y = startLine.slope * x + startLine.yIntercept
            
            switch (x < self.voronoiPoint.x, y < self.voronoiPoint.y) {
            case (true, true):
                self.usedCorners.append(.BottomLeft)
            case (true, false):
                self.usedCorners.append(.BottomRight)
            case (false, true):
                self.usedCorners.append(.TopLeft)
            case (false, false):
                self.usedCorners.append(.TopRight)
            }
        }
        
        var last = lastPoint
        var corners:[CGPoint] = []
        while !first.liesOnAxisWith(last) {
            if last.x ~= 0.0 {
                if first.y ~= 0.0 && !self.usedCorner(.BottomLeft) {
                    corners.append(Corner.BottomLeft.get(self.boundaries))
                } else {
                    
                }
            }
            if last.x ~= self.boundaries.width {
                
            }
        }
        return corners
    }
    
    internal func connectFirst_2(first:CGPoint, toLast last:CGPoint, startLine:VoronoiCellEdge, endLine:VoronoiCellEdge) -> [CGPoint] {
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
    
    internal func connectToCorners(vertices:[CGPoint]) -> [CGPoint] {
        guard let first = vertices.first, second = vertices.objectAtIndex(1), nextToLast = vertices.objectAtIndex(vertices.count - 2), last = vertices.last else {
            return []
        }
        
        let startLine = Line(start: second, end: first, voronoi: self.voronoiPoint)
        let endLine = Line(start: nextToLast, end: last, voronoi: self.voronoiPoint)
        
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
    
    
    private func point(point:CGPoint, liesAbove line:VoronoiCellEdge) -> Bool {
        //y = mx + b
        //y - mx = b
        //Above: y - mx > b
        //Below: y - mx < b
        return point.y - line.slope * point.x > line.yIntercept
    }
    
    private func point(point:CGPoint, isLeftOf startLine:VoronoiCellEdge, and endLine:VoronoiCellEdge) -> Bool {
        //Parallel (or potentially the same lines).
        if startLine.slope ~= endLine.slope {
            //If the slope of a line is greater than 0, then a point above
            //the line is also to its left. If the slope is less than 0,
            //then a point below the line is to its left.
            if startLine.slope > 0.0 {
                return self.point(point, liesAbove: startLine)
            } else {
                return !self.point(point, liesAbove: startLine)
            }
        }
        let xIntersection = (endLine.yIntercept - startLine.yIntercept) / (startLine.slope - endLine.slope)
        //let y = startLine.slope * xIntersection + startLine.yIntercept
        return point.x < xIntersection
    }
    
    private func usedCorner(corner:Corner) -> Bool {
        return self.usedCorners.contains(corner)
    }

}