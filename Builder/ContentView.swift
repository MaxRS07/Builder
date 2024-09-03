//
//  ContentView.swift
//  Builder
//
//  Created by Max Siebengartner on 21/8/2024.
//

import SwiftUI
import RealityKit
import ARKit

struct ContentView : View {
    @StateObject private var game = BuildingGame()
    var body: some View {
        Group {
            if UIDevice.isIPhone {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
                    .overlay(alignment: .center) {
                        GameOverlayIPhone()
                    }
            } else if UIDevice.isIPad {
                ARViewContainer()
                    .edgesIgnoringSafeArea(.all)
                    .overlay {
                        IpadDetail()
                    }
            }
        }
        .environmentObject(game)
    }
}
struct ARViewContainer: UIViewRepresentable {
    @EnvironmentObject var game: BuildingGame
    func makeUIView(context: Context) -> ARView {
        
        let arView = BuilderARView(frame: .zero)
        
        let mesh = MeshResource.generateBox(size: 0.1, cornerRadius: 0.005)
        let wood = MaterialTypes.Wood.instantiate(mesh: mesh)
        wood.name = "wood1"
        let wood2 = MaterialTypes.Wood.instantiate(mesh: mesh)
        let steel = MaterialTypes.Steel.instantiate(mesh: mesh)
        let steel2 = MaterialTypes.Steel.instantiate(mesh: mesh)
        let steel3 = MaterialTypes.Steel.instantiate(mesh: mesh)
        wood.position = .init(-0.2, 0.0, 0)
        wood2.position = .init(0.2, 0.0, 0)
        steel.position = .init(-0.2, 0.1, 0)
        steel2.position = .init(0.2, 0.1, 0)
        steel3.position = .init(0, 0.23, 0)
        
        let stick = MeshResource.generateBox(width: 0.5, height: 0.01, depth: 0.1)
        let beam = MaterialTypes.Wood.instantiate(mesh: stick)
        beam.name = "beam"
        beam.position = .init(0, 0.22, 0)
        
        //anchor.children.append(settings)
        let anchor = anchor
        anchor.children.append(collisionPlane)
        anchor.children.append(wood)
        anchor.children.append(wood2)
        anchor.children.append(steel)
        anchor.children.append(steel2)
        anchor.children.append(beam)
        anchor.children.append(steel3)
        
        
        arView.scene.anchors.append(anchor)
        
        BuildingSystem.registerSystem()
        
        return arView
    }
    func updateUIView(_ uiView: ARView, context: Context) {
        if let anchor = uiView.scene.anchors.first {
            for i in anchor.children {
                if let b = i as? BuildingEntity, let bc = b.buildingComponent {
                    bc.game.gravity = game.gravity
                    bc.game.loadVisuals = game.loadVisuals
                    b.components.set(bc)
                }
            }
        }
    }
    var anchor: AnchorEntity {
        let anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: SIMD2<Float>(0.2, 0.2)))
//        let material = SimpleMaterial(color: .green, isMetallic: false)
//        let mesh2 = MeshResource.generateSphere(radius: 0.01)
//        
//        anchor.components.set(ModelComponent(mesh: mesh2, materials: [material]))
        return anchor
    }
    var collisionPlane: Entity {
        let collisionPlane = ModelEntity(mesh: .generatePlane(width: 1, depth: 1), materials: [SimpleMaterial()])
        collisionPlane.position = SIMD3<Float>(0, -0.10, 0)
        let shapeResource = [ShapeResource.generateBox(width: 2, height: 0.1, depth: 2)]
        collisionPlane.physicsBody = PhysicsBodyComponent(
            shapes: shapeResource,
            mass: 1,
            mode: .static
        )
        collisionPlane.collision = CollisionComponent(shapes: shapeResource, mode: .default, filter: .default)
        collisionPlane.components.remove(ModelComponent.self)
        collisionPlane.generateCollisionShapes(recursive: true)
        return collisionPlane
    }
}
#Preview {
    ContentView()
}
