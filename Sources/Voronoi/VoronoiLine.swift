//
//  VoronoiLine.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/11/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

/**
 An extremely lightweight struct that represents a line segment.
 */
internal struct VoronoiLine {
    ///The starting point of the line.
    internal var startPoint:Point
    //The ending point of thte line.
    internal var endPoint:Point
    
    ///A unit vector starting at the start point and pointing in the direction of the end point.
    internal var directionVector:Point { return (self.endPoint - self.startPoint).unit() }
    ///The slope of the line.
    internal var slope:Double {
        //Negative recipricol to get the actual slope perpendicular to the focii.
        return (self.endPoint.y - self.startPoint.y) / (self.endPoint.x - self.startPoint.x)
    }
    ///The y-intercept of the line.
    internal var yIntercept:Double {
        return self.startPoint.y - self.slope * self.startPoint.x
    }
    ///true if this line is vertical (the start and end points have the same x-coordinate), false otherwise.
    internal var isVertical:Bool { return self.startPoint.x ~= self.endPoint.x }
    ///true if the voronoi point associated with this line lies above this line, false if below.
    internal fileprivate(set) var voronoiPointLiesAbove:Bool = false
    
    internal init(start:Point, end:Point, voronoi:Point) {
        self.startPoint = start
        self.endPoint = end
        self.voronoiPointLiesAbove = self.pointLiesAbove(voronoi)
    }
    
    ///Returns whether a point lies above this line or not.
    internal func pointLiesAbove(_ point:Point) -> Bool {
        if self.isVertical {
            return point.x < self.startPoint.x
        } else {
            return point.y - self.slope * point.x > self.yIntercept
        }
    }
    
}
