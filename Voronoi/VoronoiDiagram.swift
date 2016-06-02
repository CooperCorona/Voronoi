//
//  VoronoiDiagram.swift
//  Voronoi
//
//  Created by Cooper Knaak on 2/7/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import UIKit
import OmniSwift

// TODO: Make VoronoiDiagram initializer handle duplicates and out of bounds points.

/**
 Given a set of voronoi points and the boundaries of the diagram, uses Fortune's
 algorithm to calculate the edges between the voronoi points.
 */
public class VoronoiDiagram: NSObject {
    
    ///An array of voronoi points.
    public let points:[CGPoint]
    ///The size of the boundary rect.
    public let size:CGSize
    ///The tree used to store the beach line and search when new parabolas are added.
    private var parabolaTree = ExposedBinarySearchTree<VoronoiParabola>()
    ///The number of parabolas on the beach line
    ///(the parabolaTree property does not store this, so we have to store it here).
    private var parabolaCount = 0
    ///The edges between two voronoi points, formed by the intersection of
    ///two parabolas on the beach line.
    private var edges:[VoronoiEdge] = []
    ///The events (ordered by minimum y-coordinate, then minimum x-coordinate) that
    ///cause changes in the beach line.
    private var events = PriorityQueue<VoronoiEvent>(ascending: true, startingValues: [])
    ///The cells that correspond to each voronoi point and encapsulate the edges / vertices around it.
    private let cells:[VoronoiCell]
    ///The position of the sweep line. Formula: ```y = sweepLine```.
    public internal(set) var sweepLine:CGFloat = 0.0
    ///The result of sweeping (calculated by ```sweep```). Since the array of points is
    ///constant, ```sweep``` returns this value immediately if it already has been calculated.
    private var result:VoronoiResult? = nil
    
    ///The circle events that have been calculated.
    ///Used to make sure the same circle event is not processed twice.
    private var circleEvents:[VoronoiCircleEvent] = []
    
    /**
     Initializes a VoronoiDiagram with voronoi points and boundaries.
     - parameter points: An array of voronoi points. Currently doesn't check for duplicates or out of bounds points.
     - parameter size: The size of the the boundaries of the diagram.
     - returns: A VoronoiDiagram (that has **not** yet calculated the edges).
     */
    public init(points:[CGPoint], size:CGSize) {
        self.points = points
        self.size   = size
        self.cells  = points.map() { VoronoiCell(point: $0, boundaries: size) }
        
        super.init()
        
        for cell in self.cells {
            self.events.push(VoronoiSiteEvent(cell: cell))
        }
        
    }
    
    ///Calculates the edges of the VoronoiDiagram. Returns a VoronoiResult that exposes
    ///access to the diagram in different formats. If the result has already been calculated,
    ///it returns immediately rather than recalculating.
    public func sweep() -> VoronoiResult {
        if let result = self.result {
            return result
        }
        
        while self.events.count > 0 {
            self.sweepOnce()
        }
        
        var vertices:[CGPoint] = []
        for edge in self.edges {
            if !vertices.contains(edge.startPoint) {
                vertices.append(edge.startPoint)
            }
            if !vertices.contains(edge.endPoint) {
                vertices.append(edge.endPoint)
            }
        }
        let result = VoronoiResult(cells: self.cells, edges: self.edges, vertices: vertices)
        self.result = result
        return result
    }
    
    ///Performs one iteration (processes one event).
    private func sweepOnce() {
        
        if let event = self.events.pop() {
            if let circleEvent = event as? VoronoiCircleEvent where circleEvent.parabola == nil || event.point.y < self.sweepLine {
                self.sweepOnce()
                return
            }
            self.sweepLine = event.point.y
            event.performEvent(self)
        }
        
        if self.events.count == 0 {
            self.finishEdges()
        }

    }

    /**
     Determines the parabola on the beach line directly above a given x-coordinate.
     - parameter x: An x-coordinate.
     - returns: The parabola above the given x-coordinate
     (this always exists if there is a parabola in the beach line).
     */
    private func findParabolaAtX(x:CGFloat) -> VoronoiParabola? {
        var lastParabola:VoronoiParabola? = nil
        var currentParabola = self.parabolaTree.root
        while let parab = currentParabola {
            lastParabola = currentParabola
            guard let left = parab.getNearestLeftChild(), right = parab.getNearestRightChild() else {
                break
            }
            let intersections = VoronoiParabola.parabolaCollisions(left.focus, focus2: right.focus, directrix: self.sweepLine)
            let xIntersection:CGFloat
            if left.focus.y < right.focus.y {
                xIntersection = intersections.minElement({ $0.x < $1.x })!.x
            } else {
                xIntersection = intersections.maxElement({ $0.x < $1.x })!.x
            }
            if xIntersection > x {
                currentParabola = parab.left
            } else {
                currentParabola = parab.right
            }
        }
        return lastParabola
    }
    
    ///Adds a parabola corresponding to a VoronoiCell's underlying voronoi point to the beach line.
    internal func addPoint(cell:VoronoiCell) {
        let point = cell.voronoiPoint
        guard self.parabolaCount > 0 else {
            let parab = VoronoiParabola(cell: cell)
            self.parabolaTree.insert(parab)
            self.parabolaCount += 1
            return
        }
        guard let parab = self.findParabolaAtX(point.x) else {
            return
        }
        parab.directix  = self.sweepLine
        let rightParab  = VoronoiParabola(cell: parab.cell)
        let leftParab   = VoronoiParabola(cell: rightParab.cell)
        let newParab    = VoronoiParabola(cell: cell)
        parab.left      = leftParab
        parab.right     = VoronoiParabola(cell: VoronoiCell(point: CGPoint.zero, boundaries: CGSize.zero)) // Dummy parabola, needs two childern
        parab.right?.left  = newParab
        parab.right?.right = rightParab
        
        let y = parab.yForX(point.x)
        //I'm checking for a count of 3 because it means
        //there was only one parabola in the original array
        if self.parabolaCount == 3 && parab.focus.y ~= point.y {
            let start           = CGPoint(x: (parab.focus.x + point.x) / 2.0, y: self.size.height)
            let edge            = VoronoiEdge(start: start, left: parab.cell, right: cell)
            self.edges.append(edge)
        } else {
            
            if let ce = parab.circleEvent {
                if ce.center.x > parab.focus.x {
                    rightParab.circleEvent = parab.circleEvent
                    rightParab.circleEvent?.parabola = rightParab
                } else {
                    leftParab.circleEvent = parab.circleEvent
                    leftParab.circleEvent?.parabola = leftParab
                }
                parab.circleEvent = nil
            }
            
            let start           = CGPoint(x: point.x, y: y)
            let leftEdge        = VoronoiEdge(start: start, left: parab.cell, right: cell)
            let rightEdge       = VoronoiEdge(start: start, left: cell, right: parab.cell)
            self.edges.append(leftEdge)
            self.edges.append(rightEdge)
            
            leftParab.leftEdge      = parab.leftEdge
            rightParab.rightEdge    = parab.rightEdge
            leftEdge.leftParabola   = leftParab
            leftEdge.rightParabola  = newParab
            rightEdge.leftParabola  = newParab
            rightEdge.rightParabola = rightParab
            
            //Make left-left and right-right neighbors because
            //we flip the left right orientation on the edges
            leftEdge.leftCellEdge.makeNeighbor(rightEdge.rightCellEdge)
            leftEdge.rightCellEdge.makeNeighbor(rightEdge.leftCellEdge)
        }
        
        self.parabolaCount += 3
        
        self.checkCircleEventForParabola(leftParab)
        self.checkCircleEventForParabola(rightParab)
    }
    
    ///Removes a parabola from the beach line corresponding to a circle event's parabola.
    internal func removeParabolaFromCircleEvent(event:VoronoiCircleEvent) {
        guard let parabola = event.parabola else {
            return
        }
        let leftChild  = parabola.getParabolaToLeft()
        let rightChild = parabola.getParabolaToRight()
        var addNewEdge = false
        if let lChild  = leftChild {
            lChild.circleEvent?.parabola    = nil
            lChild.circleEvent              = nil
            if let edge = lChild.rightEdge {
                edge.endPoint  = event.center
                edge.leftParabola = nil
                edge.rightParabola = nil
                addNewEdge = true
            }
        }
        if let rChild = rightChild {
            rChild.circleEvent             = nil
            rChild.circleEvent?.parabola   = nil
            
            if let edge = rChild.leftEdge {
                edge.endPoint  = event.center
                edge.leftParabola = nil
                edge.rightParabola = nil
                addNewEdge = true
            }
        }
        
        if addNewEdge {
            let edge = VoronoiEdge(start: event.center, left: leftChild!.cell, right: rightChild!.cell)
            edge.leftParabola = leftChild
            edge.rightParabola = rightChild
            self.edges.append(edge)
            
            if let leftEdge = parabola.leftEdge, rightEdge = parabola.rightEdge {
                VoronoiEdge.makeNeighborsFirst(leftEdge, second: rightEdge, third: edge)
            }
        }
        //I've made sure that only leaves get processed with circle events.
        //Here we're just seeing which node the parent was, so we can
        //remove it by replacing it with its other child.
        if let parent = parabola.parent, let grandParent = parent.parent {
            if parabola.isLeftChild {
                if parent.isLeftChild {
                    grandParent.left = parent.right
                } else {
                    grandParent.right = parent.right
                }
            } else {
                if parent.isLeftChild {
                    grandParent.left = parent.left
                } else {
                    grandParent.right = parent.left
                }
            }
        }
        
        self.parabolaCount -= 1
        
        if let lChild = leftChild {
            self.checkCircleEventForParabola(lChild)
        }
        if let rChild = rightChild {
            self.checkCircleEventForParabola(rChild)
        }
    }
    
    ///Determines if a parabola has a circle event (it eventually
    ///becomes "squeezed" out of the beach line by its neighbors)
    private func checkCircleEventForParabola(parabola:VoronoiParabola) {

        guard let leftChild     = parabola.getParabolaToLeft() else {
            return
        }
        guard let rightChild    = parabola.getParabolaToRight() else {
            return
        }
        guard let circle        = VoronoiDiagram.calculateCircle([leftChild.focus, parabola.focus, rightChild.focus]) else {
            return
        }
        
        guard circle.center.y + circle.radius >= self.sweepLine else {
            return
        }
        
        guard let leftEdge = leftChild.rightEdge, rightEdge = rightChild.leftEdge, let p = self.calculateCollisionOfEdges(leftEdge, right: rightEdge) where p ~= circle.center else {
            return
        }
        
        let event = VoronoiCircleEvent(point: circle.center, radius: circle.radius, parabola: parabola)
        if self.circleEvents.contains({ $0.isEqualTo(event) }) {
            return
        }

        parabola.circleEvent = event
        self.events.push(event)
        self.circleEvents.append(event)
    }
    
    /**
     Determines if two edges actually will intersect. Just because the two lines
     intersect, doesn't mean the edges will, because they might be pointing away from each other.
     - parameter left: The VoronoiEdge on the left.
     - paramater right: The VoronoiEdge on the right.
     - returns: The intersection of the edge (which is the same as the center of a circle event),
     or nil if no such intersection exists.
     */
    private func calculateCollisionOfEdges(left:VoronoiEdge, right:VoronoiEdge) -> CGPoint? {
        let x = (left.yIntercept - right.yIntercept) / (right.slope - left.slope)
        let y = left.slope * x + left.yIntercept

        if (x - left.startPoint.x) / left.directionVector.x > 0.0 {
            return nil
        }
        if (y - left.startPoint.y) / left.directionVector.y > 0.0 {
            return nil
        }
        if (x - right.startPoint.x) / right.directionVector.x > 0.0 {
            return nil
        }
        if (y - right.startPoint.y) / right.directionVector.y > 0.0 {
            return nil
        }
        
        return CGPoint(x: x, y: y)
    }
    
    ///Extends all edges that have not yet ended to the boundaries of the diagram.
    private func finishEdges() {
        for edge in self.edges {
            guard !edge.hasSetEnd else {
                continue
            }
            let mx:CGFloat
            if edge.directionVector.x < 0.0 {
                mx = max(self.size.width, edge.startPoint.x + 10.0)
            } else {
                mx = min(0.0, edge.startPoint.x - 10.0)
            }
            edge.endPoint = CGPoint(x: mx, y: mx * edge.slope + edge.yIntercept)
        }
    }
    
    /**
     Given three points, determines the circle that has intersects all three points.
     - parameter points: An array of points. Must contain 3 points.
     - returns: The circle that intersects all 3 points, or nil if no such
     circle exists (which occurs when three points lie on a line).
     */
    private static func calculateCircle(points:[CGPoint]) -> Circle? {
        guard points.count >= 3 else {
            return nil
        }
        let aSquared    = points[0].dot(points[0])
        let bSquared    = points[1].dot(points[1])
        let cSquared    = points[2].dot(points[2])
        let a           = (points[1].y - points[2].y)
        let b           = (points[2].y - points[0].y)
        let c           = (points[0].y - points[1].y)
        let d_a         = points[0].x * a
        let d_b         = points[1].x * b
        let d_c         = points[2].x * c
        let d           = 2.0 * (d_a + d_b + d_c)
        guard d != 0.0 else {
            return nil
        }
        let aNeg        = points[2].x - points[1].x
        let bNeg        = points[0].x - points[2].x
        let cNeg        = points[1].x - points[0].x
        let x           = (aSquared * a + bSquared * b + cSquared * c) / d
        let y           = (aSquared * aNeg + bSquared * bNeg + cSquared * cNeg) / d
        
        let center = CGPoint(x: x, y: y)
        return Circle(center: center, radius: center.distanceFrom(points[0]))
    }
    
}