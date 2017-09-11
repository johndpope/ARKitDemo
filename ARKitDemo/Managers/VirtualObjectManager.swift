//
//  VirtualObjectManager.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

class VirtualObjectManager {

    var virtualObjects: [VirtualObject] = []
    var lastUsedObject: VirtualObject?

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
            self.setVirtualObject(object, to: position, cameraTransform: cameraTransform)
            self.lastUsedObject = object
        }
    }

    // MARK: - Update Object Position

    func translate(_ object: VirtualObject, in sceneView: ARSCNView, basedOn screenPosition: CGPoint, instantly: Bool, infinitePlane: Bool) {

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

    func setPosition(for object: VirtualObject, position: float3, instantly: Bool, filterPosition: Bool, cameraTransform: matrix_float4x4) {
        if instantly {
            setVirtualObject(object, to: position, cameraTransform: cameraTransform)
        } else {
            updateVirtualObject(object, to: position, filterPosition: filterPosition, cameraTransform: cameraTransform)
        }
    }

    func setVirtualObject(_ object: VirtualObject, to position: float3, cameraTransform: matrix_float4x4) {
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

    private func updateVirtualObject(_ object: VirtualObject, to position: float3, filterPosition: Bool, cameraTransform: matrix_float4x4) {
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

    func checkIfObjectShouldMoveOntoPlane(planeAnchor: ARPlaneAnchor, planeAnchorNode: SCNNode) {
        for object in virtualObjects {
            // Get the object's position in the plane's coordinate system.
            let objectPosition = planeAnchorNode.convertPosition(object.position, from: object.parent)

            if objectPosition.y == 0 {
                return // The object is already on the plane - nothing to do here.
            }

            // Add 10% tolerance to the corners of the plane.
            let tolerance: Float = 0.1

            let minX: Float = planeAnchor.center.x - planeAnchor.extent.x / 2 - planeAnchor.extent.x * tolerance
            let maxX: Float = planeAnchor.center.x + planeAnchor.extent.x / 2 + planeAnchor.extent.x * tolerance
            let minZ: Float = planeAnchor.center.z - planeAnchor.extent.z / 2 - planeAnchor.extent.z * tolerance
            let maxZ: Float = planeAnchor.center.z + planeAnchor.extent.z / 2 + planeAnchor.extent.z * tolerance

            if objectPosition.x < minX || objectPosition.x > maxX || objectPosition.z < minZ || objectPosition.z > maxZ {
                return
            }

            // Move the object onto the plane if it is near it (within 5 centimeters).
            let verticalAllowance: Float = 0.05
            // Do not bother updating if the different is less than a mm.
            let epsilon: Float = 0.001
            let distanceToPlane = abs(objectPosition.y)

            if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                object.position.y = planeAnchor.transform.columns.3.y
                SCNTransaction.commit()
            }
        }
    }

    func transform(for object: VirtualObject, cameraTransform: matrix_float4x4) -> (distance: Float, rotation: Int, scale: Float) {
        let cameraWorldPosition = cameraTransform.translation
        let vectorToCamera = cameraWorldPosition - object.simdPosition

        let distanceToUser = simd_length(vectorToCamera)

        var angleDegrees = Int((object.eulerAngles.y * 180) / .pi) % 360
        if angleDegrees < 0 {
            angleDegrees += 360
        }

        return (distanceToUser, angleDegrees, object.scale.x)
    }

    func worldPosition(from screenPosition: CGPoint, in sceneView: ARSCNView, objectPosition: float3?, infinitePlane: Bool = false) -> (position: float3?, planeAnchor: ARPlaneAnchor? , hitAPlane: Bool) {
        let dragOnInfinitePlanesEnabled = true

        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)

        let planeHitTestResults = sceneView.hitTest(screenPosition, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {

            let planeHitTestPosition = result.worldTransform.translation
            let planeAnchor = result.anchor

            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }

        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.

        var featureHitTestPosition: float3?
        var highQualityFeatureHitTestResult = false

        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(screenPosition, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)

        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }

        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).

        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {

            if let pointOnPlane = objectPosition {
                let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(screenPosition, pointOnPlane)
                if pointOnInfinitePlane != nil {
                    return (pointOnInfinitePlane, nil, true)
                }
            }
        }

        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.

        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }

        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.

        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(screenPosition)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }

        return (nil, nil, false)
    }

}
