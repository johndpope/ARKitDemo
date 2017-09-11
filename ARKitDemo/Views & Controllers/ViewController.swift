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

    var messageManager: MessageManager!
    lazy var virtualObjectManager = VirtualObjectManager()

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
        // Release any cached data, images, etc that aren't in use.
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

    func showCancelAndConfirmButtons() {
        cancelButton.isHidden = false
        confirmButton.isHidden = false
    }
    
    func hideCancelAndConfirmButtons() {
        cancelButton.isHidden = true
        confirmButton.isHidden = true
    }

    func addVirtualOjbect(at index: Int) {
        guard let cameraTransform = sceneView.session.currentFrame?.camera.transform else {
            return
        }

        let definition = VirtualObjectManager.availableObjectDefinitions[index]
        let object = VirtualObject(definition: definition)

        let screenCenter = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        let (worldPosition, _, _) = virtualObjectManager.worldPosition(from: screenCenter, in: sceneView, objectPosition: float3(0))
        let position = worldPosition ?? float3(0)

        virtualObjectManager.loadVirtualObject(object, to: position, cameraTransform: cameraTransform)

        if object.parent == nil {
            DispatchQueue.global().async {
                self.sceneView.scene.rootNode.addChildNode(object)
            }
        }
    }

    // MARK: - Actions

    @IBAction func addButtonTapped() {
        addButton.isHidden = true
        closeButton.isHidden = false
        showCollectionViewAndCloseButton()
    }

    @IBAction func closeButtonTapped() {
        addButton.isHidden = false
        closeButton.isHidden = true
        hideCollectionViewAndCloseButton(animated: true)
    }

    @IBAction func cancelButtonTapped() {
        addButton.isHidden = false
        hideCancelAndConfirmButtons()
    }

    @IBAction func confirmButtonTapped() {

    }

    // MARK: - ARSCNViewDelegate

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
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
        virtualObjectManager.reactToTouchesBegan(touches, with: event, in: self.sceneView)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesEnded(touches, with: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        virtualObjectManager.reactToTouchesCancelled(touches, with: event)
    }

}
