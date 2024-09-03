//
//  BuilderARView.swift
//  Builder
//
//  Created by Max Siebengartner on 21/8/2024.
//

import Foundation
import RealityKit
import ARKit

class BuilderARView: ARView, ARSessionObserver, ARSessionDelegate {
    
    required init(frame frameRect: CGRect) {
        super.init(frame: frameRect)
        self.session.delegate = self
    }
    
    
    @MainActor required dynamic init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.session.delegate = self
    }
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        print("hello")
    }
}
