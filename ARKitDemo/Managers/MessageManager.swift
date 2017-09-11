//
//  MessageManager.swift
//  ARKitDemo
//
//  Created by Lebron on 10/09/2017.
//  Copyright © 2017 HackNCraft. All rights reserved.
//

import Foundation
import UIKit
import ARKit

class MessageManager {

    var messageLabel: UILabel
    var timer: Timer?

    // MARK: - Initialization

    init(messageLabel: UILabel) {
        self.messageLabel = messageLabel
    }

    // MARK: - ARKit

    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool = true) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }

    // MARK: - Message Handling

    func showMessage(_ text: String, autoHide: Bool = true) {
        DispatchQueue.main.async {
            self.timer?.invalidate()

            self.messageLabel.text = text
            self.messageLabel.isHidden = false

            if autoHide {
                // Compute an appropriate amount of time to display the on screen message.
                // According to https://en.wikipedia.org/wiki/Words_per_minute, adults read
                // about 200 words per minute and the average English word is 5 characters
                // long. So 1000 characters per minute / 60 = 15 characters per second.
                // We limit the duration to a range of 1-10 seconds.
                let charCount = text.characters.count
                let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
                self.timer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false, block: { [weak self] _ in
                    guard let strongSelf = self else {
                        return
                    }
                    strongSelf.messageLabel.isHidden = true
                })
            }
        }
    }

}

extension ARCamera.TrackingState {

    var presentationString: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"

        case .normal:
            return "TRACKING NORMAL"

        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "TRACKING LIMITED\nToo much camera movement"
            case .insufficientFeatures:
                return "TRACKING LIMITED\nNot enough surface detail"
            case .initializing:
                return "Initializing AR Session"
            }
        }
    }

}
