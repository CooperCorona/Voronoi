//
//  Circle.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit

///Represents a circle defined by its center and radius. Used to 
///calculate VoronoiCircleEvents.
public struct Circle {
    
    ///The center of the circle.
    public var center = CGPoint.zero
    ///The radius of the circle.
    public var radius:CGFloat = 0.0
    
    public init() {
        
    }
    
    public init(center:CGPoint, radius:CGFloat) {
        self.center = center
        self.radius = radius
    }
    
}