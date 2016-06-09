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
public  class VoronoiEvent: Comparable {
    
    ///The point at which the event is triggerred.
    public  let point:CGPoint
    
    ///Initializes a VoronoiEvent with a given point.
    public  init(point:CGPoint) {
        self.point = point
    }
    
    ///Triggers the event on the VoronoiDiagram.
    public  func performEvent(diagram:VoronoiDiagram) {
        
    }

}

// MARK: - Comparable Protocol

public  func ==(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs.point.y == rhs.point.y
}

public  func <(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    if lhs.point.y ~= rhs.point.y {
        return lhs.point.x < rhs.point.x
    } else {
        return lhs.point.y < rhs.point.y
    }
}

public  func >(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    if lhs.point.y ~= rhs.point.y {
        return lhs.point.x > rhs.point.x
    } else {
        return lhs.point.y > rhs.point.y
    }
}

public  func <=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs == rhs || lhs < rhs
}

public  func >=(lhs:VoronoiEvent, rhs:VoronoiEvent) -> Bool {
    return lhs == rhs || lhs > rhs
}
