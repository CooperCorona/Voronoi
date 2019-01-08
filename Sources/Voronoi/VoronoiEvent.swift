//
//  VoronoiEvent.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/7/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import CoronaConvenience
import CoronaStructures
import CoronaGL

///Represents an event that happens when the sweep line crosses a specific point.
internal class VoronoiEvent: Comparable, CustomStringConvertible {
    
    ///The point at which the event is triggerred.
    internal let point:CGPoint
    
    internal var description: String { return "VoronoiEvent(\(self.point))" }
    
    ///Initializes a VoronoiEvent with a given point.
    internal init(point:CGPoint) {
        self.point = point
    }
    
    ///Triggers the event on the VoronoiDiagram.
    internal func performEvent(_ diagram:VoronoiDiagram) {
        
    }

}

// MARK: - Comparable Protocol

internal func ==(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y == rhs.point.y
}

internal func <(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    if lhs.point.y ~= rhs.point.y {
        if lhs is VoronoiCircleEvent && rhs is VoronoiSiteEvent {
            return false
        } else if lhs is VoronoiSiteEvent && rhs is VoronoiCircleEvent {
            return true
        }
        return lhs.point.x < rhs.point.x
    } else {
        return lhs.point.y < rhs.point.y
    }
}

internal func >(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    
    if lhs.point.y ~= rhs.point.y {
        if lhs is VoronoiCircleEvent && rhs is VoronoiSiteEvent {
            return true
        } else if lhs is VoronoiSiteEvent && rhs is VoronoiCircleEvent {
            return false
        }
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
