//
//  VirtualObjectManager.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

class VirtualObjectManager: ObjectManager {
    var virtualObjects: [VirtualObject] = []
    var lastUsedObject: Object?

    static let availableObjectDefinitions: [VirtualObjectDefinition] = {
        guard let jsonURL = Bundle.main.url(forResource: "VirtualObjectsInfo", withExtension: "json") else {
            fatalError("missing expected VirtualObjectsInfo in bundle")
        }

        do {
            let jsonData = try Data(contentsOf: jsonURL)
            return try JSONDecoder().decode([VirtualObjectDefinition].self, from: jsonData)
        } catch {
            fatalError("can't load virtual objects JSON: \(error)")
        }
    }()

    // MARK: - Reset Objects

    func removeAllVirtualObjects() {
        for object in virtualObjects {
            unloadVirtualObject(object)
        }

        virtualObjects.removeAll()
    }

    func removeVirtualObject(at index: Int) {
        let definition = VirtualObjectManager.availableObjectDefinitions[index]
        guard let object = virtualObjects.first(where: { $0.definition == definition }) else {
            return
        }

        unloadVirtualObject(object)

        if let objectIndex = virtualObjects.index(of: object) {
            virtualObjects.remove(at: objectIndex)
        }
    }

    func unloadVirtualObject(_ object: VirtualObject) {
        DispatchQueue.global().async {
            object.unloadModel()
            object.removeFromParentNode()

            if self.lastUsedObject == object {
                self.lastUsedObject = nil

                if self.virtualObjects.count > 1 {
                    self.lastUsedObject = self.virtualObjects[0]
                }
            }
        }
    }

    // MARK: - Load Objects

    func loadVirtualObject(_ object: VirtualObject, to position: float3, cameraTransform: matrix_float4x4) {
        virtualObjects.append(object)

        DispatchQueue.global().async {
            object.loadModel()
            object.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            object.physicsBody?.mass = 2
            self.setVirtualObject(object, to: position, cameraTransform: cameraTransform)
            self.lastUsedObject = object
        }
    }

    // MARK: - React to gestures

    var currentGesture: Gesture?

    func reactToTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in sceneView: ARSCNView) {
        if virtualObjects.isEmpty {
            return
        }

        if currentGesture == nil {
            currentGesture = Gesture.startGesture(from: touches,
                                                  sceneView: sceneView,
                                                  lastUsedObject: lastUsedObject, 
                                                  objectManager: self)
            if let newObject = currentGesture?.lastUsedObject as? VirtualObject {
                lastUsedObject = newObject
            }
        } else {
            currentGesture = currentGesture?.updateGesture(from: touches, .touchBegan)
            if let newObject = currentGesture?.lastUsedObject as? VirtualObject {
                lastUsedObject = newObject
            }
        }
    }

    func reactToTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }

        currentGesture = currentGesture?.updateGesture(from: touches, .touchMoved)
        if let newObject = currentGesture?.lastUsedObject as? VirtualObject {
            lastUsedObject = newObject
        }
    }

    func reactToTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }
        currentGesture = currentGesture?.updateGesture(from: touches, .touchEnded)
        if let newObject = currentGesture?.lastUsedObject as? VirtualObject {
            lastUsedObject = newObject
        }
    }

    func reactToTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if virtualObjects.isEmpty {
            return
        }
        currentGesture = currentGesture?.updateGesture(from: touches, .touchCancelled)
    }

}
