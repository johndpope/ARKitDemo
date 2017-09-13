//
//  ViewController.swift
//  ARKitDemo
//
//  Created by Lebron on 09/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - Properties

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    
    @IBOutlet var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewBottomCloseButtonConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewBottomMessageLabelConstraint: NSLayoutConstraint!
    @IBOutlet var closeButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var addButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsButtonTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var cancelAndConfirmButtonBottomConstraints: [NSLayoutConstraint]!

    var messageManager: MessageManager!

    var currentHelperNode: PlacementHelperNode?
    var currentHelperNodeAngle: Float = 0
    var currentHelperNodePosition = float3(0, 0, 0)
    var selectedObjectIndex: Int = 0

    var largeTransparentPlane: SCNNode?

    lazy var virtualObjectManager = VirtualObjectManager()
    lazy var placementHelperNodeManager = PlacementHelperNodeManager()
    var objectManager: ObjectManager {
        return (currentHelperNode == nil) ? virtualObjectManager : placementHelperNodeManager
    }

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]

        messageManager = MessageManager(messageLabel: messageLabel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideCollectionViewAndCloseButton(animated: false)
        animateAddButton(hide: true, animated: false)
        animateCancelAndConfirmButtons(hide: true, animated: false)
        animateSettingsButton(hide: true, animated: false)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Private Methods

    func hideCollectionViewAndCloseButton(animated: Bool) {
        let duration = animated ? 0.25 : 0
        UIView.animate(withDuration: duration, animations: {
            self.collectionViewTopConstraint.isActive = false
            self.collectionViewBottomCloseButtonConstraint.isActive = false
            self.closeButtonBottomConstraint.constant = -60
            self.view.layoutIfNeeded()
        })
    }

    func animateAddButton(hide: Bool, animated: Bool) {
        let duration = animated ? 0.25 : 0
        let constant: CGFloat = hide ? -60 : 20
        UIView.animate(withDuration: duration, animations: {
            self.addButtonBottomConstraint.constant = constant
            self.view.layoutIfNeeded()
        })
    }

    func addButtonIsHidden() -> Bool {
        return addButtonBottomConstraint.constant == -60
    }

    func animateSettingsButton(hide: Bool, animated: Bool) {
        let duration = animated ? 0.25 : 0
        let constant: CGFloat = hide ? -60 : 20
        UIView.animate(withDuration: duration, animations: {
            self.settingsButtonTrailingConstraint.constant = constant
            self.view.layoutIfNeeded()
        })
    }

    func animateCancelAndConfirmButtons(hide: Bool, animated: Bool) {
        let duration = animated ? 0.25 : 0
        let constant: CGFloat = hide ? -60 : 20
        UIView.animate(withDuration: duration, animations: {
            self.cancelAndConfirmButtonBottomConstraints.forEach({ constraint in
                constraint.constant = constant
            })
            self.view.layoutIfNeeded()
        })
    }

    private func showCollectionViewAndCloseButton() {
        collectionViewHeightConstraint.isActive = false
        collectionViewBottomMessageLabelConstraint.isActive = false

        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.4,
                       options: [.curveEaseInOut],
                       animations: {
                        self.collectionViewTopConstraint.isActive = true
                        self.collectionViewBottomCloseButtonConstraint.isActive = true
                        self.closeButtonBottomConstraint.constant = 20
                        self.view.layoutIfNeeded()
        }, completion: { _ in

            UIView.animate(withDuration: 0.25, animations: {
                self.closeButtonBottomConstraint.constant = 20
                self.view.layoutIfNeeded()
            })
        })
    }

    func addVirtualOjbect(at index: Int) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            return
        }

        let definition = VirtualObjectManager.availableObjectDefinitions[index]
        let object = VirtualObject(definition: definition)

        guard let virtualObjectManager = objectManager as? VirtualObjectManager else {
            return
        }

        virtualObjectManager.loadVirtualObject(object, to: currentHelperNodePosition, cameraTransform: cameraTransform)

        object.eulerAngles.y = currentHelperNodeAngle

        if object.parent == nil {
            DispatchQueue.global().async {
                self.sceneView.scene.rootNode.addChildNode(object)
            }
        }
    }

    func addPlacementHelperNode(at index: Int) {
        let helperNode = PlacementHelperNode()
        helperNode.simdPosition = worldPositionFromScreenCenter()

        DispatchQueue.global().async {
            self.sceneView.scene.rootNode.addChildNode(helperNode)
        }

        currentHelperNode = helperNode
    }

    func addALargeTransparentPlane() {
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1, alpha: 0)

        let bottomPlane = SCNBox(width: 1000, height: 0.001, length: 1000, chamferRadius: 0)
        bottomPlane.materials = [material]

        let planeNode = SCNNode(geometry: bottomPlane)
        planeNode.simdPosition = worldPositionFromScreenCenter()
        planeNode.physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)

        sceneView.scene.rootNode.addChildNode(planeNode)

        largeTransparentPlane = planeNode
    }

    func worldPositionFromScreenCenter() -> float3 {
        let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        let (worldPosition, _, _) = objectManager.worldPosition(from: screenCenter, in: sceneView, objectPosition: float3(0))
        return worldPosition ?? float3(0)
    }

    // MARK: - Actions

    @IBAction func addButtonTapped() {
        animateAddButton(hide: true, animated: true)
        showCollectionViewAndCloseButton()
    }

    @IBAction func closeButtonTapped() {
        animateAddButton(hide: false, animated: true)
        hideCollectionViewAndCloseButton(animated: true)
    }

    @IBAction func cancelButtonTapped() {
        animateAddButton(hide: false, animated: true)
        animateCancelAndConfirmButtons(hide: true, animated: true)

        currentHelperNode?.removeFromParentNode()
        currentHelperNode = nil
    }

    @IBAction func confirmButtonTapped() {
        animateCancelAndConfirmButtons(hide: true, animated: true)
        animateAddButton(hide: false, animated: true)

        if let helperNode = currentHelperNode {
            currentHelperNodeAngle = helperNode.eulerAngles.y
            currentHelperNodePosition = helperNode.simdPosition
        }

        currentHelperNode?.removeFromParentNode()
        currentHelperNode = nil

        addVirtualOjbect(at: selectedObjectIndex)
    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        messageManager.showMessage("FIND A SURFACE TO PLACE AN OBJECT")

        if addButtonIsHidden() {
            animateAddButton(hide: false, animated: true)
        }

        if largeTransparentPlane == nil {
            addALargeTransparentPlane()
        }
    }

    // MARK: - ARSessionObserver

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        messageManager.showTrackingQualityInfo(for: camera.trackingState)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }

    // MARK: - Gesture Recognizers

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        objectManager.reactToTouchesBegan(touches, with: event, in: self.sceneView)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        objectManager.reactToTouchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        objectManager.reactToTouchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        objectManager.reactToTouchesCancelled(touches, with: event)
    }

}
