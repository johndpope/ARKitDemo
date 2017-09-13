//
//  Object.swift
//  ARKitDemo
//
//  Created by Lebron on 13/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import ARKit

class Object: SCNNode {
    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentDistances: [Float] = []
}
