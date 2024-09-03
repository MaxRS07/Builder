//
//  BoringUtils.swift
//  Builder
//
//  Created by Max Siebengartner on 23/8/2024.
//

import Foundation
import SwiftUI
import ARKit
import RealityKit

extension UIColor {
    static func multiLerp(colors: [UIColor], value: CGFloat) -> UIColor {
        guard !colors.isEmpty, (0...1).contains(value) else {
            return .clear
        }
        
        let count = CGFloat(colors.count)
        let position = max(0, min(count - 1, value * (count - 1)))
        let lowerIndex = Int(position)
        let upperIndex = min(lowerIndex + 1, Int(count) - 1)
        
        let lowerColor = colors[lowerIndex]
        let upperColor = colors[upperIndex]
        
        let lowerAlpha = lowerColor.cgColor.alpha
        let upperAlpha = upperColor.cgColor.alpha
        
        var lowerRed: CGFloat = 0, lowerGreen: CGFloat = 0, lowerBlue: CGFloat = 0
        lowerColor.getRed(&lowerRed, green: &lowerGreen, blue: &lowerBlue, alpha: nil)
        
        var upperRed: CGFloat = 0, upperGreen: CGFloat = 0, upperBlue: CGFloat = 0
        upperColor.getRed(&upperRed, green: &upperGreen, blue: &upperBlue, alpha: nil)
        
        let t = position - CGFloat(lowerIndex)
        let red = lowerRed + (upperRed - lowerRed) * t
        let green = lowerGreen + (upperGreen - lowerGreen) * t
        let blue = lowerBlue + (upperBlue - lowerBlue) * t
        let alpha = lowerAlpha + (upperAlpha - lowerAlpha) * t
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    static func colorLerp(min: UIColor, max: UIColor, value: Float) -> UIColor {
        var r1 = CGFloat(), g1 = CGFloat(), b1 = CGFloat(), a1 = CGFloat(), r2 = CGFloat(), g2 = CGFloat(), b2 = CGFloat(), a2 = CGFloat()
        min.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        max.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = lerp(min: r1, max: r2, value: CGFloat(value))
        let g = lerp(min: g1, max: g2, value: CGFloat(value))
        let b = lerp(min: b1, max: b2, value: CGFloat(value))
        let a = lerp(min: a1, max: a2, value: CGFloat(value))
        
        return UIColor.init(red: r, green: g, blue: b, alpha: a)
    }
    func mix(_ other: UIColor) -> UIColor {
        var r1 = CGFloat(), g1 = CGFloat(), b1 = CGFloat(), a1 = CGFloat(), r2 = CGFloat(), g2 = CGFloat(), b2 = CGFloat(), a2 = CGFloat()
        self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor.init(red: (r1 + r2) / 2, green: (g1 + g2) / 2, blue: (b1 + b2) / 2, alpha: (a1 + a2) / 2)
    }
    static func *(lhs: UIColor, rhs: UIColor) -> UIColor {
        var r1 = CGFloat(), g1 = CGFloat(), b1 = CGFloat(), a1 = CGFloat(), r2 = CGFloat(), g2 = CGFloat(), b2 = CGFloat(), a2 = CGFloat()
        lhs.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        rhs.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return UIColor.init(red: r1 * r2, green: g1 * g2, blue: b1 * b2, alpha: a1 * a2)
    }
}
public func lerp<T>(min: T, max: T, value: T) -> T where T: Numeric {
    return min + (max - min) * value
}
public func clamp<T>(min: T, max: T, value: T) -> T where T: Comparable {
    return value < min ? min : value > max ? max : value
}
extension BoundingBox {
    static func +(lhs: BoundingBox, rhs: SIMD3<Float>) -> BoundingBox {
        let min = lhs.min + rhs
        let max = lhs.max + rhs
        
        return BoundingBox(min: min, max: max)
    }
    static func +=(lhs: inout BoundingBox, rhs: SIMD3<Float>) {
        lhs = lhs + rhs
    }
}
struct BoxCastRect {
    let min: SIMD3<Float>
    let max: SIMD3<Float>
    
    var w: Float {
        return max.x - min.x
    }
    var l: Float {
        return max.z - min.z
    }
    
    init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }
    ///surface normal
    func normal() -> SIMD3<Float> {
        let t = SIMD3(min.x, max.y, max.z)
        let l = SIMD3(max.x, max.y, min.z)
        return cross(t, l)
    }
}
extension RealityKit.Scene {
    func boxcast(start: BoxCastRect, dist: Float, samples: Int = 3) -> [CollisionCastHit] {
        var info: [[CollisionCastHit]] = []
        for x in 1...samples {
            for y in 1...samples {
                let offx = start.w * Float(x) / Float(samples + 1)
                let offz = start.l * Float(y) / Float(samples + 1)
                let result = self.raycast(origin: start.min + SIMD3(offx, 0, offz), direction: start.normal(), length: 0.001, query: .all, mask: .all)
                info.append(result)
            }
        }
        var result: [CollisionCastHit] = []
        info.forEach({$0.forEach{e in
            if !result.contains(e) {
                result.append(e)
            }
        }})
        return result
    }
}
extension SIMD3<Float> {
    static let unitX: Self = .init(1, 0, 0)
    static let unitY: Self = .init(0, 1, 0)
    static let unitZ: Self = .init(0, 0, 1)
}
extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}
func generateCurvedBeam(width: Float, height: Float, depth: Float, curve: Float, numSegments: Int) -> MeshResource {
    var vertices: [simd_float3] = []
    
    for i in 0..<numSegments {
        let t = Float(i) / Float(numSegments)
        let x = t * width - width / 2
        let y = curve * -((t - 0.5) * (t - 0.5))
        let z = depth / 2
        
        let lt = simd_float3(x, y, -z)
        let rt = simd_float3(x, y, z)
        let lb = simd_float3(x, y - height, -z)
        let rb = simd_float3(x, y - height, z)
        
        vertices.append(contentsOf: [lt, rt, lb, rb])
    }
    var indices: [UInt32] = []
    for i in stride(from: 0, to: vertices.count-4, by: 4) {
        let lt = UInt32(i)
        let rt = UInt32(i + 1)
        let lb = UInt32(i + 2)
        let rb = UInt32(i + 3)
        let lt2 = UInt32(i + 4)
        let rt2 = UInt32(i + 5)
        let lb2 = UInt32(i + 6)
        let rb2 = UInt32(i + 7)
        
        func triangle(_ a: UInt32, _ b: UInt32, _ c: UInt32) {
            indices.append(contentsOf: [a, b, c])
        }
        
        triangle(lt, rt, rt2) //top face
        triangle(rt2, lt2, lt)
        
        triangle(lb, rb2, rb) //bottom face
        triangle(lb, lb2, rb2)

        triangle(rt, rb, rb2) //right face
        triangle(rb2, rt2, rt)
        
        triangle(lb, lt, lb2) //left face
        triangle(lb2, lt, lt2 )
        
        if i == 0 {
            triangle(rt, lt, rb) //back face
            triangle(lb, rb, lt)
        }
        if i == vertices.count - 8 {
            triangle(lb2, lt2, rt2) //forward face
            triangle(rt2, rb2, lb2)
        }
    }
    var vnorms: [SIMD3<Float>] = .init(repeating: .zero, count: vertices.count)
    var faceCount = [Int](repeating: 0, count: vertices.count)

    for i in stride(from: 0, to: indices.count, by: 3) {
        let aIndex = Int(indices[i])
        let bIndex = Int(indices[i + 1])
        let cIndex = Int(indices[i + 2])
        
        let a = vertices[aIndex]
        let b = vertices[bIndex]
        let c = vertices[cIndex]
        
        let normal = normalize(cross(b - a, c - a))
        
        [aIndex, bIndex, cIndex].forEach { index in
            vnorms[index] += normal
            faceCount[index] += 1
        }
    }
    for i in vnorms.indices {
        if faceCount[i] > 0 {
            vnorms[i] = normalize(vnorms[i] / Float(faceCount[i]))
        }
    }
    
    var desc = MeshDescriptor(name: "curvedBeam")
    desc.positions = MeshBuffers.Positions(vertices)
    desc.primitives = .triangles(indices)
//    desc.normals = .init(vnorms)
    do {
        return try MeshResource.generate(from: [desc])
    } catch {
        print(error.localizedDescription)
    }
    exit(0)
}
