//
//  VoronoiDiagram+Factory.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/11/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaMath

extension VoronoiDiagram {

    ///Returns a random number in the range [0, 1].
    ///- returns: A random number in the range [0, 1].
    private class func randomUniform() -> Double {
        var random = SystemRandomNumberGenerator()
        return Double.random(in: 0...1.0, using: &random)
    }
    
    /**
     Creates a VoronoiDiagram object with a given size and random voronoi points.
     - parameter size: The size of the voronoi diagram.
     - parameter points: The number of voronoi points.
     - parameter buffer: The minimum distance from the edges of the boundaries the
     points can be generated at.
     - returns: A VoronoiDiagram object with randomly generated voronoi points.
     */
    public class func createWithSize(_ size:Size, points:Int, buffer:Double = 0.0) -> VoronoiDiagram {
        let frame = Rect(x: buffer, y: buffer, width: size.width - 2.0 * buffer, height: size.height - 2.0 * buffer)
        var voronoiPoints:[Point] = []
        while voronoiPoints.count < points {
            let x = VoronoiDiagram.randomUniform()
            let y = VoronoiDiagram.randomUniform()
            let p = frame.interpolate(point: Point(x: x, y: y))
            if frame.contains(point: p) {
                voronoiPoints.append(p)
            }
        }
        return VoronoiDiagram(points: voronoiPoints, size: size)
    }
    
    /**
     Creates a VoronoiDiagram object with a given size and random voronoi points. Each
     voronoi point is generated in its own subrectangle of the boundaries.
     - parameter size: The size of the voronoi diagram.
     - parameter rows: The number of rows of voronoi points (the total number of points is `rows * columns`).
     - parameter columns: The number of columns of voronoi points.
     - parameter range: A number in the range (0.0, 1.0] that is multiplied into the subrectangle's size
     to constrain the position of the voronoi points.
     - returns: A VoronoiDiagram object with randomly generated (but constrained) voronoi points.
     */
    public class func createWithSize(_ size:Size, rows:Int, columns:Int, range:Double) -> VoronoiDiagram {
        let pointRange = Point(x: size.width / Double(rows), y: size.height / Double(columns))
        var voronoiPoints:[Point] = []
        for j in 0..<columns {
            for i in 0..<rows {
                let o = Point(x: Double(i) + 0.5, y: Double(j) + 0.5) * pointRange
                let x = VoronoiDiagram.randomUniform() - 0.5
                let y = VoronoiDiagram.randomUniform() - 0.5
                let p = Point(x: x, y: y) * pointRange * range + o
                voronoiPoints.append(p)
            }
        }
        return VoronoiDiagram(points: voronoiPoints, size: size)
    }
}
