//
//  PlacementHelperPlane.swift
//  ARKitDemo
//
//  Created by Lebron on 11/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import SceneKit
import ARKit

class PlacementHelperPlane: SCNNode {

//    var anchor: ARPlaneAnchor
    var planeGeometry: SCNBox

    override init() {
//        self.anchor = anchor

//        let width = anchor.extent.x
//        let length = anchor.extent.z
        let width = 0.5
        let length = 0.5
        let planeHeight: CGFloat = 0.01

        self.planeGeometry = SCNBox(width: CGFloat(width), height: planeHeight, length: CGFloat(length), chamferRadius: 0)

        super.init()

        let transparentMaterial = self.transparentMaterial()
        let material = self.material(at: 0)

        planeGeometry.materials = [transparentMaterial, transparentMaterial, transparentMaterial, transparentMaterial, material!, transparentMaterial];

        let planeNode = SCNNode(geometry: planeGeometry)
        planeNode.position = SCNVector3Make(0, Float(-planeHeight / 2), 0)
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))

        addChildNode(planeNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

//    func update(for anchor: ARPlaneAnchor) {
//        planeGeometry.width = CGFloat(anchor.extent.x)
//        planeGeometry.length = CGFloat(anchor.extent.z)
//
//        position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
//
//        let node = childNodes.first
//        node?.physicsBody = SCNPhysicsBody(type: .kinematic, shape: SCNPhysicsShape(geometry: planeGeometry, options: nil))
//    }
//
//    func update(for worldPosition: float3, camera: ARCamera) {
//        simdPosition = worldPosition
//    }

    func setTextureScale() {
        let width = Float(planeGeometry.width)
        let height = Float(planeGeometry.length)

        let material = planeGeometry.materials[4]
        let scaleFactor: Float = 1

        let matrix4 = SCNMatrix4MakeScale(width * scaleFactor, height * scaleFactor, 1)
        material.diffuse.contentsTransform = matrix4
        material.roughness.contentsTransform = matrix4
        material.metalness.contentsTransform = matrix4
        material.normal.contentsTransform = matrix4
    }

    func remove() {
        removeFromParentNode()
    }

    func material(at index: Int) -> SCNMaterial? {

        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "add")
        material.diffuse.wrapS = .repeat
        material.diffuse.wrapT = .repeat

        return material

        //        var materialName = ""
        //
        //        switch index {
        //        case 0:
        //            materialName = "tron"
        //        case 1:
        //            materialName = "oakfloor2"
        //        case 2:
        //            materialName = "sculptedfloorboards"
        //        case 3:
        //            materialName = "granitesmooth"
        //        case 4:
        //            // planes will be transparent
        //            return nil
        //        default:
        //            return nil
        //        }
        //
        //        return MaterialManager.material(named: materialName)
    }

    func transparentMaterial() -> SCNMaterial {
        let transparentMaterial = SCNMaterial()
        transparentMaterial.diffuse.contents = UIColor(white: 1, alpha: 0)
        return transparentMaterial
    }

}

