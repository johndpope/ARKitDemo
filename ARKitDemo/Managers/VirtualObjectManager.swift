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
    var lastUsedObject: SCNNode?

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

    // MARK: - Update Object Position

    func translate(_ object: SCNNode, in sceneView: ARSCNView, basedOn screenPosition: CGPoint, instantly: Bool, infinitePlane: Bool) {
        guard let object = object as? VirtualObject else {
            return
        }


        DispatchQueue.main.async {
            let result = self.worldPosition(from: screenPosition, in: sceneView, objectPosition: object.simdPosition, infinitePlane: infinitePlane)

            guard let newPosition = result.position,
                let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
                    return
            }

            DispatchQueue.global().async {
                self.setPosition(for: object,
                                 position: newPosition,
                                 instantly: instantly,
                                 filterPosition: !result.hitAPlane,
                                 cameraTransform: cameraTransform)
            }
        }
    }

    func setPosition(for object: SCNNode, position: float3, instantly: Bool, filterPosition: Bool, cameraTransform: matrix_float4x4) {
        guard let object = object as? VirtualObject else {
            return
        }

        if instantly {
            setVirtualObject(object, to: position, cameraTransform: cameraTransform)
        } else {
            updateVirtualObject(object, to: position, filterPosition: filterPosition, cameraTransform: cameraTransform)
        }
    }

    func setVirtualObject(_ object: SCNNode, to position: float3, cameraTransform: matrix_float4x4) {
        guard let object = object as? VirtualObject else {
            return
        }

        let cameraWorldPosition = cameraTransform.translation
        var cameraToPosition = position - cameraWorldPosition

        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }

        object.simdPosition = cameraWorldPosition + cameraToPosition
        object.recentDistances.removeAll()
    }

    func updateVirtualObject(_ object: SCNNode, to position: float3, filterPosition: Bool, cameraTransform: matrix_float4x4) {
        guard let object = object as? VirtualObject else {
            return
        }

        let cameraWorldPosition = cameraTransform.translation
        var cameraToPosition = position - cameraWorldPosition

        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(cameraToPosition) > 10 {
            cameraToPosition = simd_normalize(cameraToPosition)
            cameraToPosition *= 10
        }

        // Compute the average distance of the object from the camera over the last ten
        // updates. If filterPosition is true, compute a new position for the object
        // with this average. Notice that the distance is applied to the vector from
        // the camera to the content, so it only affects the percieved distance of the
        // object - the averaging does _not_ make the content "lag".
        let hitTestResultDistance = simd_length(cameraToPosition)

        object.recentDistances.append(hitTestResultDistance)
        object.recentDistances.keepLast(10)

        if filterPosition, let averageDistance = object.recentDistances.average {
            let averagedDistancePosition = cameraWorldPosition + simd_normalize(cameraToPosition) * averageDistance
            object.simdPosition = averagedDistancePosition
        } else {
            object.simdPosition = cameraWorldPosition + cameraToPosition
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
