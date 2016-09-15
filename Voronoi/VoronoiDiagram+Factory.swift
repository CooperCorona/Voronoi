//
//  VoronoiDiagram+Factory.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/11/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import UIKit
import CoronaConvenience
import CoronaStructures
import CoronaGL

extension VoronoiDiagram {
    
    /**
     Creates a VoronoiDiagram object with a given size and random voronoi points.
     - parameter size: The size of the voronoi diagram.
     - parameter points: The number of voronoi points.
     - parameter buffer: The minimum distance from the edges of the boundaries the
     points can be generated at.
     - returns: A VoronoiDiagram object with randomly generated voronoi points.
     */
    public class func createWithSize(size:CGSize, points:Int, buffer:CGFloat = 0.0) -> VoronoiDiagram {
        let frame = CGRect(x: buffer, y: buffer, width: size.width - 2.0 * buffer, height: size.height - 2.0 * buffer)
        var voronoiPoints:[CGPoint] = []
        while voronoiPoints.count < points {
            let x = GLSParticleEmitter.randomFloat()
            let y = GLSParticleEmitter.randomFloat()
            let p = frame.interpolate(CGPoint(x: x, y: y))
            if frame.contains(p) {
                voronoiPoints.append(p)
            }
        }
        return VoronoiDiagram(points: voronoiPoints, size: size)
    }
    
    /**
     Creates a VoronoiDiagram object with a given size and random voronoi points. Each
     voronoi point is generated in its own subrectangle of the boundaries.
     - parameter size: The size of the voronoi diagram.
     - parameter rows: The number of rows of voronoi points (the total number of points is ```rows * columns```).
     - parameter columns: The number of columns of voronoi points.
     - parameter range: A number in the range (0.0, 1.0] that is multiplied into the subrectangle's size
     to constrain the position of the voronoi points.
     - returns: A VoronoiDiagram object with randomly generated (but constrained) voronoi points.
     */
    public class func createWithSize(size:CGSize, rows:Int, columns:Int, range:CGFloat) -> VoronoiDiagram {
        let pointRange = CGSize(width: size.width / CGFloat(rows), height: size.height / CGFloat(columns))
        var voronoiPoints:[CGPoint] = []
        for j in 0..<columns {
            for i in 0..<rows {
                let o = CGPoint(x: CGFloat(i) + 0.5, y: CGFloat(j) + 0.5) * pointRange
                let x = GLSParticleEmitter.randomFloat() - 0.5
                let y = GLSParticleEmitter.randomFloat() - 0.5
                let p = CGPoint(x: x, y: y) * pointRange * range + o
                voronoiPoints.append(p)
            }
        }
        return VoronoiDiagram(points: voronoiPoints, size: size)
    }
}