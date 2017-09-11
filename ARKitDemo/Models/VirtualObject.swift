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

class VirtualObject: SCNNode {

    let definition: VirtualObjectDefinition
    let referenceNode: SCNReferenceNode

    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentDistances: [Float] = []

    init(definition: VirtualObjectDefinition) {
        self.definition = definition

        guard let modelURL = Bundle.main.url(forResource: "Models.scnassets/\(definition.modelName)/\(definition.modelName)", withExtension: "scn") else {
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
