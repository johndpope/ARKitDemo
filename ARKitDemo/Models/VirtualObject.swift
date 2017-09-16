//
//  VirtualObject.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import SceneKit

struct VirtualObjectDefinition: Codable, Equatable {

    let modelName: String
    let displayName: String
    let particleScaleInfo: [String: Float]

    lazy var thumbImage = UIImage(named: modelName)

    init(modelName: String, displayName: String, particleScaleInfo: [String: Float] = [:]) {
        self.modelName = modelName
        self.displayName = displayName
        self.particleScaleInfo = particleScaleInfo
    }

    static func ==(lhs: VirtualObjectDefinition, rhs: VirtualObjectDefinition) -> Bool {
        return lhs.modelName == rhs.modelName
            && lhs.displayName == rhs.displayName
            && lhs.particleScaleInfo == rhs.particleScaleInfo
    }

}

class VirtualObject: Object {

    let definition: VirtualObjectDefinition
    let referenceNode: SCNReferenceNode

    init(definition: VirtualObjectDefinition) {
        self.definition = definition

//        guard let modelURL = Bundle.main.url(forResource: "Models.scnassets/\(definition.modelName)/\(definition.modelName)", withExtension: "scn") else {
//            fatalError("can't find Models.scnassets/\(definition.modelName)/\(definition.modelName).scn file")
//        }

        guard let modelURL = Bundle.main.url(forResource: "Models.scnassets/Warehouse Rack Set/racks1", withExtension: "obj") else {
            fatalError("can't find Models.scnassets/\(definition.modelName)/\(definition.modelName).scn file")
        }

        guard let node = SCNReferenceNode(url: modelURL) else {
            fatalError("can't find expected virtual object bundle resources")
        }

        referenceNode = node

        super.init()

        addChildNode(node)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadModel() {
        referenceNode.load()
    }

    func unloadModel() {
        referenceNode.unload()
    }

    var isModelLoaded: Bool {
        return referenceNode.isLoaded
    }

}

extension VirtualObject {

    static func castNodeToVirtualObject(node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }

        if node.parent != nil {
            return castNodeToVirtualObject(node: node.parent!)
        }

        return nil
    }

}

// MARK: - Scale

protocol Scaleable {
    func reactToScale()
}

extension SCNNode {
    func reactsToScale() -> Scaleable? {
        if let canReact = self as? Scaleable {
            return canReact
        }

        if let parent = self.parent {
            return parent.reactsToScale()
        }

        return nil
    }
}

extension VirtualObject: Scaleable {
    func reactToScale() {
        for (nodeName, particleSize) in definition.particleScaleInfo {
            guard let node = self.childNode(withName: nodeName, recursively: true),
                let particleSystem = node.particleSystems?.first else {
                    continue
            }
            particleSystem.reset()
            particleSystem.particleSize = CGFloat(scale.x * particleSize)
        }
    }
}
