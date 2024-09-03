//
//  BuilderGame.swift
//  Builder
//
//  Created by Max Siebengartner on 21/8/2024.
//

import Foundation
import RealityKit
import ARKit


public class BuildingGame: ObservableObject {

    @Published var gravity = Float(1.81)
    @Published var menuOpen: Bool = false
    @Published var loadVisuals: Bool = false
    @Published var selected: [BuildingEntity]?
}
struct BuildingComponent: Component {
    public var game: BuildingGame
    
    init(game: BuildingGame) {
        self.game = game
    }
}
class BuildingSystem: System {
    private static let query = EntityQuery(where: .has(BuildingComponent.self))
    
    required init(scene: Scene) {
    }
    func update(context: SceneUpdateContext) {
        let entities = context.scene.performQuery(Self.query)
        for entity in entities {
            if let building = entity as? BuildingEntity {
                let force = compressivePressure(for: building, context: context)
                let depth = building.bbox.z
                let width = building.bbox.x
                let height = building.bbox.y
                    let x = depth * width
                    let max = building.materialProperties.mechanicalProperties.cmpStr * x
                    let frat = abs(force / max)
                    let coef = clamp(min: 0, max: 1, value: frat)
                    
                    
                    let e = building.materialProperties.mechanicalProperties.flexStr
                    let i = height * height * height * width / Float(12)
                    let d = (force * depth * depth * depth) / (48 * e * i)
                    
                    if building.name == "beam" {
                        let curve = generateCurvedBeam(width: width, height: height, depth: depth, curve: d, numSegments: 30)
                        building.rebake(mesh: curve)
                    }
                    
                    let bm = force * depth / 4
                    let c = height / 2
                    let fs = abs(bm * c / i)
                    
                    let coeffs = clamp(min: 0, max: 1, value: fs / e)
                    
                    if coeffs >= 1 && building.name == "beam" {
                        let p1 = building.position - simd_float3(-width / 4, 0, 0)
                        let p2 = building.position + simd_float3(width / 4, 0, 0)
                        
                        let stick = MeshResource.generateBox(width: width / 2, height: height, depth: depth)
                        
                        let half1 = MaterialTypes.Wood.instantiate(mesh: stick)
                        let half2 = MaterialTypes.Wood.instantiate(mesh: stick)
                        
                        half1.position = p1
                        half2.position = p2
                        
                        if let a = context.scene.anchors.first {
                            a.children.append(half1)
                            a.children.append(half2)
                            a.children.remove(building)
                        }
                    } else if coef >= 1 {
                        //let s
                    }
                        
                if var model = building.model {
                    guard let color = building.materialProperties.materials.first as? SimpleMaterial else {return}
                    var c = color.color.tint
                    var indicator = UIColor.multiLerp(colors: [.green, .yellow, .red], value: CGFloat(coef))
                    if building.name == "beam" {
                        indicator = UIColor.multiLerp(colors: [.green, .yellow, .red], value: CGFloat(coeffs))
                    }
                    if let bc = building.buildingComponent, bc.game.loadVisuals {
                        c = indicator
                    }
                    
                    if var material = model.materials.first as? SimpleMaterial {
                        material.color.tint = c
                        model.materials = [material]
                        building.components.set(model)
                    }
                }
                
                var bodies: [BuildingEntity] = []
                var thisEntity = building
                while let joint = thisEntity.components[JointComponent.self] as? JointComponent {
                    thisEntity = joint.connectedBody
                    bodies.append(thisEntity)
                }
                bodies.reduce(0, { x, y in
                    x + (y.physicsBody?.massProperties.mass ?? 0)
                })
            }
        }
    }
    func compressivePressure(for entity: BuildingEntity, context: SceneUpdateContext) -> Newtons {
        var total = Float()
        func totalPressure(for entity2: BuildingEntity, context: SceneUpdateContext) {
            if var bbox = entity2.model?.mesh.bounds {
                bbox.min.y = bbox.max.y
                bbox.max.y += 0.003
                bbox += entity2.position
                for e in context.scene.performQuery(Self.query) {
                    if e.id == entity2.id { continue }
                    if let b = e as? BuildingEntity, var bbox2 = b.model?.mesh.bounds {
                        bbox2 += b.position
                        if bbox2.intersects(bbox) {
                            if let m = b.physicsBody?.massProperties.mass, let v = b.physicsMotion?.linearVelocity {
                                let p = v.y * v.y * m / Float(2)
                                let fg = m * -(b.buildingGame.gravity)
                                total += fg + p
                                //totalPressure(for: b, context: context)
                            }
                        }
                    }
                }
            }
        }
        totalPressure(for: entity, context: context)
        return total
    }
}
class JointComponent: Component {
    let connectedBody: BuildingEntity
    
    init(connectedBody: BuildingEntity) {
        self.connectedBody = connectedBody
    }
}

