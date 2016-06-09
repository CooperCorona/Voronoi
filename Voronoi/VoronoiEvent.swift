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

///Represents an event that happens when the sweep line crosses a specific point.
internal class VoronoiEvent: Comparable {
    
    ///The point at which the event is triggerred.
    internal let point:CGPoint
    
    ///Initializes a VoronoiEvent with a given point.
    internal init(point:CGPoint) {
        self.point = point
    }
    
    ///Triggers the event on the VoronoiDiagram.
    internal func performEvent(diagram:VoronoiDiagram) {
        
    }

}

// MARK: - Comparable Protocol

internal func ==(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y == rhs.point.y
}

internal func <(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    if lhs.point.y ~= rhs.point.y {
        return lhs.point.x < rhs.point.x
    } else {
        return lhs.point.y < rhs.point.y
    }
}

internal func >(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    if lhs.point.y ~= rhs.point.y {
        return lhs.point.x > rhs.point.x
    } else {
        return lhs.point.y > rhs.point.y
    }
}

internal func <=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs == rhs || lhs < rhs
}

internal func >=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs == rhs || lhs > rhs
}
