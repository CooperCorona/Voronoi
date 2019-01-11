//
//  Circle.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

///Represents a circle defined by its center and radius. Used to 
///calculate VoronoiCircleEvents.
public struct Circle {
    
    ///The center of the circle.
    public var center = Point.zero
    ///The radius of the circle.
    public var radius:Double = 0.0
    
    public init() {
        
    }
    
    public init(center:Point, radius:Double) {
        self.center = center
        self.radius = radius
    }
    
}
