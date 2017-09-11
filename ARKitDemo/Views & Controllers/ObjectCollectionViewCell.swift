//
//  ObjectCollectionViewCell.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import UIKit

class ObjectCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var objectImageView: UIImageView!
    @IBOutlet weak var objectLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

//        backgroundColor = UIColor(white: 0, alpha: 0.5)
    }

}
