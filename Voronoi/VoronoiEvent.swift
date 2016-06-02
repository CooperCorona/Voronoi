//
//  VoronoiEvent.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/7/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import UIKit
import OmniSwift

internal class VoronoiEvent: Comparable {
    internal let point:CGPoint
    
    internal init(point:CGPoint) {
        self.point = point
    }
    
    internal func performEvent(diagram:VoronoiDiagram) {
        
    }
}

internal class SiteEvent: VoronoiEvent {
    
    private let cell:VoronoiCell
    
    internal init(cell:VoronoiCell) {
        self.cell = cell
        super.init(point: cell.voronoiPoint)
    }
    
    internal override func performEvent(diagram: VoronoiDiagram) {
        diagram.sweepLine = self.point.y
        diagram.addPoint(self.cell)
    }
}

internal class CircleEvent: VoronoiEvent {
    
    let center:CGPoint
    let radius:CGFloat
    weak var parabola:VoronoiParabola?
    
    internal init(point:CGPoint, radius:CGFloat, parabola:VoronoiParabola) {
        self.center = point
        self.parabola = parabola
        self.radius = radius
        super.init(point: point + CGPoint(y: radius))
    }
    
    internal override func performEvent(diagram: VoronoiDiagram) {
        diagram.sweepLine = self.point.y
        diagram.removeParabolaFromCircleEvent(self)
    }

    internal func isEqualTo(event:CircleEvent) -> Bool {
        return self.center ~= event.center && self.radius ~= event.radius
    }
}

internal func ==(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y == rhs.point.y
}

internal func <(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y < rhs.point.y
}

internal func >(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y > rhs.point.y
}

internal func <=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y <= rhs.point.y
}

internal func >=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y >= rhs.point.y
}
