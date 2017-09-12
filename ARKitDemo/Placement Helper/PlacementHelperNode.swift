//
//  PlacementHelperNode.swift
//  ARKitDemo
//
//  Created by Lebron on 12/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation

import SceneKit
import ARKit

class PlacementHelperNode: SCNNode {

    var recentDistances: [Float] = []

    override init() {
        super.init()

        let height: CGFloat = 0.001
        let width: CGFloat = 1
        let length: CGFloat = 1

        let rectangleNode = geometryNodeFromImage(named: "rectangle", width: width, height: height, length: length)
        let downArrowNode = geometryNodeFromImage(named: "down-arrow", width: width, height: height, length: length)
        let ovalNode = geometryNodeFromImage(named: "oval", width: width, height: height, length: length)

        addChildNode(ovalNode)
        addChildNode(rectangleNode)
        addChildNode(downArrowNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func geometryNodeFromImage(named name: String, width: CGFloat, height: CGFloat, length: CGFloat) -> SCNNode {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0)

        let rectangleMaterial = SCNMaterial()
        rectangleMaterial.diffuse.contents = UIImage(named: name)
        box.materials = [rectangleMaterial]

        return SCNNode(geometry: box)
    }

}

extension PlacementHelperNode {

    static func castNodeToPlacementHelperNode(node: SCNNode) -> PlacementHelperNode? {
        if let virtualObjectRoot = node as? PlacementHelperNode {
            return virtualObjectRoot
        }

        if node.parent != nil {
            return castNodeToPlacementHelperNode(node: node.parent!)
        }

        return nil
    }

}
