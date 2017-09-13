//
//  PlacementHelperNodeManager.swift
//  ARKitDemo
//
//  Created by Lebron on 11/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

class PlacementHelperNodeManager: ObjectManager {

    var lastUsedObject: Object?

    // MARK: - React to gestures

    var currentGesture: Gesture?

    func reactToTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?, in sceneView: ARSCNView) {
        if currentGesture == nil {
            currentGesture = Gesture.startGesture(from: touches,
                                                  sceneView: sceneView,
                                                  lastUsedObject: lastUsedObject,
                                                  objectManager: self)
            if let newObject = currentGesture?.lastUsedObject as? PlacementHelperNode {
                lastUsedObject = newObject
            }
        } else {
            currentGesture = currentGesture?.updateGesture(from: touches, .touchBegan)
            if let newObject = currentGesture?.lastUsedObject as? PlacementHelperNode {
                lastUsedObject = newObject
            }
        }
    }

    func reactToTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentGesture = currentGesture?.updateGesture(from: touches, .touchMoved)
        if let newObject = currentGesture?.lastUsedObject as? PlacementHelperNode {
            lastUsedObject = newObject
        }
    }

    func reactToTouchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentGesture = currentGesture?.updateGesture(from: touches, .touchEnded)
        if let newObject = currentGesture?.lastUsedObject as? PlacementHelperNode {
            lastUsedObject = newObject
        }
    }

    func reactToTouchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentGesture = currentGesture?.updateGesture(from: touches, .touchCancelled)
    }

}
