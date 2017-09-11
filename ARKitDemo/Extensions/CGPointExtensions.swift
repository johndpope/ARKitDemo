//
//  CGPointExtensions.swift
//  ARKitDemo
//
//  Created by Lebron on 11/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

extension CGPoint {

    init(_ size: CGSize) {
        self.x = size.width
        self.y = size.height
    }

    init(_ vector: SCNVector3) {
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }

    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }

    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }

    func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }

    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }

    static func / (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x / right, y: left.y / right)
    }

    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }

    static func /= (left: inout CGPoint, right: CGFloat) {
        left = left / right
    }

    static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }
}
