//
//  Blocks.swift
//  Builder
//
//  Created by Max Siebengartner on 21/8/2024.
//

import Foundation
import RealityKit
import ARKit


typealias Pascal = Float
typealias Newtons = Float
typealias WattPerMeterKelvin = Float
typealias JoulePerKgKelvin = Float
typealias SquareMeterKelvinPerWatt = Float

struct MechanicalProperties {
    var cmpStr: Pascal
    var tenStr: Pascal
    var flexStr: Pascal //mod of rupture
    var shearStr: Pascal
    var elaMod: Pascal
    
    init(cmpStr: Pascal, tenStr: Pascal, flexStr: Pascal, shearStr: Pascal, elaMod: Pascal) {
        self.cmpStr = cmpStr
        self.tenStr = tenStr
        self.flexStr = flexStr
        self.shearStr = shearStr
        self.elaMod = elaMod
    }
}
///per kg
struct MaterialCost {
    var earbon: Float //kg
    var energy: Float //kWh
    var cash: Float   //usd
    
    init(earbon: Float, energy: Float, cash: Float) {
        self.earbon = earbon
        self.energy = energy
        self.cash = cash
    }
}
struct ThermalProperties {
    var conduction: WattPerMeterKelvin
    var capacity: JoulePerKgKelvin
    var expansion: Float //multiplier for length per kelvin increase
    var resistance: Float
    var flammability: Float
    
    init(conduction: WattPerMeterKelvin, capacity: JoulePerKgKelvin, expansion: Float, resistance: Float, flammability: Float) {
        self.conduction = conduction
        self.capacity = capacity
        self.expansion = expansion
        self.resistance = resistance
        self.flammability = flammability
    }
}
public struct MaterialProperties {
    var type: MaterialTypes
    var density: Float
    var staticFriction: Float
    var dynamicFriction: Float
    var restitution: Float
    var thermalProperties: ThermalProperties
    var cost: MaterialCost
    var mechanicalProperties: MechanicalProperties
    var materials: [any Material]
    
    init(type: MaterialTypes, density: Float, staticFriction: Float, dynamicFriction: Float, restitution: Float, thermalProperties: ThermalProperties, cost: MaterialCost, mechanicalProperties: MechanicalProperties, materials: [any Material]) {
        self.type = type
        self.density = density
        self.staticFriction = staticFriction
        self.dynamicFriction = dynamicFriction
        self.restitution = restitution
        self.thermalProperties = thermalProperties
        self.cost = cost
        self.mechanicalProperties = mechanicalProperties
        self.materials = materials
    }
    static var new: MaterialProperties {
        return MaterialProperties(type: .Debug, density: 1, staticFriction: 0, dynamicFriction: 0, restitution: 0, thermalProperties: .init(conduction: 0, capacity: 0, expansion: 0, resistance: 0, flammability: 0), cost: .init(earbon: 0, energy: 0, cash: 0), mechanicalProperties: .init(cmpStr: 0, tenStr: 0, flexStr: 0, shearStr: 0, elaMod: 0), materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
    }
}
public class BuildingEntity: Entity, HasModel, HasCollision, HasPhysics {
    public let materialProperties: MaterialProperties
    public var buildingGame: BuildingGame
    
    public var bbox: SIMD3<Float>
    
    var buildingComponent: BuildingComponent? {
        return self.components[BuildingComponent.self] as? BuildingComponent
    }
    init(mesh: MeshResource, materialProperties: MaterialProperties, game: BuildingGame) {
        self.materialProperties = materialProperties
        self.buildingGame = game
        self.bbox = mesh.bounds.extents
        super.init()
        self.model = .init(mesh: mesh, materials: materialProperties.materials)
        
        let shapeResource = ShapeResource.generateConvex(from: mesh)
        let physicsMaterial = PhysicsMaterialResource.generate(staticFriction: materialProperties.staticFriction, dynamicFriction: materialProperties.dynamicFriction, restitution: materialProperties.restitution)
        let physicsBody = PhysicsBodyComponent(shapes: [shapeResource], density: materialProperties.density, material: physicsMaterial, mode: .dynamic)
        let physicsMotion = PhysicsMotionComponent()
        let collision = CollisionComponent(shapes: [shapeResource], mode: .trigger, filter: .sensor)
        //self.generateCollisionShapes(recursive: true)
        self.components.set(physicsBody)
        self.components.set(physicsMotion)
        self.components.set(collision)
        self.components.set(BuildingComponent(game: game))
    }
    func rebake(mesh: MeshResource) {
        self.model = ModelComponent.init(mesh: mesh, materials: materialProperties.materials)
        let shapeResource = ShapeResource.generateConvex(from: mesh)
        //self.collision = CollisionComponent(shapes: [shapeResource], mode: .trigger, filter: .sensor)
        
        //self.generateCollisionShapes(recursive: true)
    }
    
    
    @MainActor required init() {
        fatalError("init() has not been implemented")
    }
}
enum MaterialTypes {
    case Wood
    case Stone
    case Steel
    case Debug
    
    
    func instantiate(mesh: MeshResource) -> BuildingEntity {
        switch self {
            case .Wood:
                break
            case .Stone:
                break
            case .Steel:
                let mechanical = MechanicalProperties(cmpStr: 5000000, tenStr: 600000000, flexStr: 700000000, shearStr: 300000000, elaMod: 200000000000)
            let thermal = ThermalProperties(conduction: 50, capacity: 500, expansion: 0.000012, resistance: 0.17, flammability: 0.45)
            let cost = MaterialCost(earbon: 2.0, energy: 7, cash: 1.25)
            let material = SimpleMaterial(color: .gray, roughness: 1, isMetallic: true)
            let materialProperties = MaterialProperties(type: .Steel, density: 8000, staticFriction: 0.74, dynamicFriction: 0.57, restitution: 0, thermalProperties: thermal, cost: cost, mechanicalProperties: mechanical, materials: [material])
            return BuildingEntity(mesh: mesh, materialProperties: materialProperties, game: BuildingGame())
            default:
                break
        }
        let mechanical = MechanicalProperties(cmpStr: 8600, tenStr: 5500000, flexStr: 99000, shearStr: 12300000, elaMod: 12560000000)
        let thermal = ThermalProperties(conduction: 0.144, capacity: 2380, expansion: 0.0000035, resistance: 0.1176, flammability: 100)
        let cost = MaterialCost(earbon: 1.8, energy: 6, cash: 11)
        let material = SimpleMaterial(color: .brown, roughness: 1, isMetallic: false)
        let materialProperties = MaterialProperties(type: .Wood, density: 600, staticFriction: 0.5, dynamicFriction: 0.4, restitution: 0, thermalProperties: thermal, cost: cost, mechanicalProperties: mechanical, materials: [material])
        return BuildingEntity(mesh: mesh, materialProperties: materialProperties, game: BuildingGame())
    }
}
