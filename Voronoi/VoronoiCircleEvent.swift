//
//  VoronoiCircleEvent.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import OmniSwift

/**
 A VoronoiEvent that occurs when the sweep line crosses the top
 of a circle formed by three consecutive voronoi points. When this
 occurs, the associated parabola is removed from the beach line, its
 edges are connected, and a new edge is formed at the intersection.
 */
internal class VoronoiCircleEvent: VoronoiEvent {
    
    ///The center of the circle. This is where the edges meet.
    let center:CGPoint
    ///The radius of the circle.
    let radius:CGFloat
    ///The parabola that will be removed when the event occurs.
    weak var parabola:VoronoiParabola?
    
    ///Initializes the event with a given circle and associated parabola.
    internal init(point:CGPoint, radius:CGFloat, parabola:VoronoiParabola) {
        self.center = point
        self.parabola = parabola
        self.radius = radius
        super.init(point: point + CGPoint(y: radius))
    }
    
    ///Moves the sweep line to the top of the circle and removes the associated parabola.
    internal override func performEvent(diagram: VoronoiDiagram) {
        diagram.sweepLine = self.point.y
        diagram.removeParabolaFromCircleEvent(self)
    }
    
    ///Determines if two circle events are the same circle.
    ///Needed because sometimes the same circle event is created
    ///twice but should not be processed twice.
    internal func isEqualTo(event:VoronoiCircleEvent) -> Bool {
        return self.center ~= event.center && self.radius ~= event.radius
    }
}