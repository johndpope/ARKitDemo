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

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!

    @IBOutlet var collectionViewTopConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewBottomCloseButtonConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var collectionViewBottomMessageLabelConstraint: NSLayoutConstraint!
    @IBOutlet var closeButtonBottomConstraint: NSLayoutConstraint!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self

        print(collectionViewTopConstraint)
        print(collectionViewBottomCloseButtonConstraint)
        print(collectionViewHeightConstraint)
        print(collectionViewBottomMessageLabelConstraint)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        hideCollectionViewAndCloseButton(animated: false)
        
        let configuration = ARWorldTrackingConfiguration()
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

    private func hideCollectionViewAndCloseButton(animated: Bool) {
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
                       usingSpringWithDamping: 0.8,
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

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
