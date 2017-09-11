//
//  ViewControllerCollectionViewExtensions.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import UIKit

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return VirtualObjectManager.availableObjectDefinitions.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ObjectCell", for: indexPath)

        guard let objectCell = cell as? ObjectCollectionViewCell else {
            return cell
        }

        var objectDefinition = VirtualObjectManager.availableObjectDefinitions[indexPath.row]

        objectCell.objectImageView.image = objectDefinition.thumbImage
        objectCell.objectLabel.text = objectDefinition.displayName

        return objectCell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        hideCollectionViewAndCloseButton(animated: true)
        showCancelAndConfirmButtons()

    }

}
