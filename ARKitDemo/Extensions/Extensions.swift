//
//  Extensions.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

extension float4x4 {
    /// Treats matrix as a (right-hand column-major convention) transform matrix
    /// and factors out the translation component of the transform.
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

extension Array where Iterator.Element == Float {
    var average: Float? {
        guard !self.isEmpty else {
            return nil
        }

        let sum = self.reduce(Float(0)) { current, next in
            return current + next
        }
        return sum / Float(self.count)
    }
}

func rayIntersectionWithHorizontalPlane(rayOrigin: float3, direction: float3, planeY: Float) -> float3? {

    let direction = simd_normalize(direction)

    // Special case handling: Check if the ray is horizontal as well.
    if direction.y == 0 {
        if rayOrigin.y == planeY {
            // The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
            // Therefore we simply return the ray origin.
            return rayOrigin
        } else {
            // The ray is parallel to the plane and never intersects.
            return nil
        }
    }

    // The distance from the ray's origin to the intersection point on the plane is:
    //   (pointOnPlane - rayOrigin) dot planeNormal
    //  --------------------------------------------
    //          direction dot planeNormal

    // Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
    let dist = (planeY - rayOrigin.y) / direction.y

    // Do not return intersections behind the ray's origin.
    if dist < 0 {
        return nil
    }

    // Return the intersection point.
    return rayOrigin + (direction * dist)
}
