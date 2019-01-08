//
//  VoronoiSiteEvent.swift
//  Voronoi
//
//  Created by Cooper Knaak on 6/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

#if os(iOS)
import UIKit
#else
import Cocoa
#endif


/**
 A VoronoiEvent that occurs when the sweep line crosses a voronoi point.
 */
internal class VoronoiSiteEvent: VoronoiEvent {
    
    ///The cell containing the given voronoi point.
    fileprivate let cell:VoronoiCell
    
    internal override var description: String { return "VoronoiSiteEvent(\(self.point))" }
    
    ///Initializes the event with a cell containing the given voronoi point.
    internal init(cell:VoronoiCell) {
        self.cell = cell
        super.init(point: cell.voronoiPoint)
    }
    
    ///Sets the VoronoiDiagram's sweep line and adds the corresponding parabola to the beach line.
    internal override func performEvent(_ diagram: VoronoiDiagram) {
        diagram.sweepLine = self.point.y
        diagram.addPoint(self.cell)
    }
    
}
