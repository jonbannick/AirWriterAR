//
//  TrackingState+Description.swift
//  Air Writer
//
//  Created by Jonathan Bannick on 10/13/17.
//  Copyright © 2017 Jonathan Bannick. All rights reserved.
//

import ARKit

extension ARCamera.TrackingState {
    public var description: String {
        switch self {
        case .notAvailable:
            return "Unable to map room"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Too much camera movement"
            case .insufficientFeatures:
                return "Not enough surface detail"
            case .initializing:
                return "Mapping Room...\nPlease move camera slowly around"
            }
        }
    }
}
