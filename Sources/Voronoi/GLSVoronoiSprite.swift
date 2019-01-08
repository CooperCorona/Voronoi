//
//  GLSVoronoiSprite.swift
//  Voronoi2
//
//  Created by Cooper Knaak on 6/9/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif

import CoronaConvenience
import CoronaStructures
import CoronaGL

open class GLSVoronoiSprite: GLSSprite {

    fileprivate var textureAnchors:[CGPoint] = []
    open override var texture: CCTexture? {
        didSet {
            self.textureChanged()
        }
    }
    
    public init(cell:VoronoiCell, boundaries:CGSize) {
        
        let vertices = cell.makeVertexLoop()
        let centerPosition = vertices.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(vertices.count)
        
        func generateVertex(_ point:CGPoint) -> UVertex {
            var v = UVertex()
            v.position = (point - centerPosition).getGLTuple()
            v.texture = (GLfloat(point.x / boundaries.width), GLfloat(point.y / boundaries.height))
            return v
        }
        
        super.init(position: centerPosition, size: CGSize.zero, texture: CCTextureOrganizer.textureForString("White Tile"))
        
        self.vertices = []
        let center = generateVertex(cell.voronoiPoint)
        for (i, current) in vertices.enumerateSkipLast() {
            let next = vertices[i + 1]
            let v2 = generateVertex(current)
            let v3 = generateVertex(next)
            self.vertices += [center, v2, v3]
        }
        if let first = vertices.first, let last = vertices.last {
            let f = generateVertex(first)
            let l = generateVertex(last)
            self.vertices += [center, l, f]
        }
        self.textureAnchors = self.vertices.map() { CGPoint(tupleGL: $0.texture) }
    }
    
    fileprivate func textureChanged() {
        guard let frame = self.texture?.frame else {
            return
        }
        //textureAnchors is guaranteed to have the same length
        //as vertices, unless the user screws with the vertices
        //for some reason, which is a user error.
        for (i, anchor) in self.textureAnchors.enumerated() {
            self.vertices[i].texture = frame.interpolate(anchor).getGLTuple()
        }
    }
}
