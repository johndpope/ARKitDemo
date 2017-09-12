//
//  SingleFingerGesture.swift
//  ARKitDemo
//
//  Created by Lebron on 11/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

class SingleFingerGesture: Gesture {

    // MARK: - Properties

    var initialTouchLocation = CGPoint()
    var latestTouchLocation = CGPoint()

    let translationThreshold: CGFloat = 30
    var translationThresholdPassed = false
    var hasMovedObject = false
    var firstTouchedObject: SCNNode?
    var dragOffset = CGPoint()

    // MARK: - Initialization

    override init(touches: Set<UITouch>,
                  sceneView: ARSCNView,
                  lastUsedObject: SCNNode?,
                  objectManager: ObjectManager) {

        super.init(touches: touches,
                   sceneView: sceneView,
                   lastUsedObject: lastUsedObject,
                   objectManager: objectManager)

        let touch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
        initialTouchLocation = touch.location(in: sceneView)
        latestTouchLocation = initialTouchLocation

        // Check if the initial touch was on the object or not.
        let results = sceneView.hitTest(initialTouchLocation, options: [SCNHitTestOption.boundingBoxOnly: true])
        for result in results {
            if let object = VirtualObject.castNodeToVirtualObject(node: result.node) {
                firstTouchedObject = object
                break
            } else if let object = PlacementHelperNode.castNodeToPlacementHelperNode(node: result.node) {
                firstTouchedObject = object
                break
            }
        }
    }

    // MARK: - Gesture Handling

    func updateGesture() {
        guard let virtualObject = firstTouchedObject else {
            return
        }

        let touch = currentTouches[currentTouches.index(currentTouches.startIndex, offsetBy: 0)]
        latestTouchLocation = touch.location(in: sceneView)

        if !translationThresholdPassed {
            let initialLocationToCurrentLocation = latestTouchLocation - initialTouchLocation
            let distanceFromStartLocation = initialLocationToCurrentLocation.length()
            if distanceFromStartLocation >= translationThreshold {
                translationThresholdPassed = true

                let currentObjectLocation = CGPoint(sceneView.projectPoint(virtualObject.position))
                dragOffset = latestTouchLocation - currentObjectLocation
            }
        }

        // A single finger drag will occur if the drag started on the object and the threshold has been passed.
        if translationThresholdPassed {

            let offsetPosition = latestTouchLocation - dragOffset
            objectManager.translate(virtualObject, in: sceneView, basedOn: offsetPosition, instantly: false, infinitePlane: true)
            hasMovedObject = true
            lastUsedObject = virtualObject
        }
    }

    func finishGesture() {

        // Single finger touch allows teleporting the object or interacting with it.

        // Do not do anything if this gesture is being finished because
        // another finger has started touching the screen.
        if currentTouches.count > 1 {
            return
        }

        // Do not do anything either if the touch has dragged the object around.
        if hasMovedObject {
            return
        }

        // If this gesture hasn't moved the object then perform a hit test against
        // the geometry to check if the user has tapped the object itself.
        var objectHit = false
        let results = sceneView.hitTest(latestTouchLocation, options: [SCNHitTestOption.boundingBoxOnly: true])

        // The user has touched the virtual object.
        for result in results {
            if VirtualObject.castNodeToVirtualObject(node: result.node) != nil {
                objectHit = true
                break
            } else if PlacementHelperNode.castNodeToPlacementHelperNode(node: result.node) != nil {
                objectHit = true
                break
            }
        }

        if lastUsedObject != nil {
            // In general, if this tap has hit the object itself then the object should
            // not be repositioned. However, if the object covers a significant
            // percentage of the screen then we should interpret the tap as repositioning
            // the object.
            if !objectHit {
                // Teleport the object to whereever the user touched the screen - as long as the
                // drag threshold has not been reached.
                if !translationThresholdPassed {
                    objectManager.translate(lastUsedObject!, in: sceneView, basedOn: latestTouchLocation, instantly: true, infinitePlane: false)
                }
            }
        }
    }

}
