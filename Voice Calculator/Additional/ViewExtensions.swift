//
//  ViewExtensions.swift
//  Voice Calculator
//
//  Created by Олег on 31.07.17.
//  Copyright © 2017 Oleg Dreyman. All rights reserved.
//

import UIKit

extension UIView {
    
    enum TransitionPushDirection {
        case fromBottom
        case fromLeft
        case fromRight
        case fromTop
        
        var coreAnimationConstant: String {
            switch self {
            case .fromBottom:
                return kCATransitionFromBottom
            case .fromTop:
                return kCATransitionFromTop
            case .fromLeft:
                return kCATransitionFromLeft
            case .fromRight:
                return kCATransitionFromRight
            }
        }
    }
    
    func pushTransition(_ direction: TransitionPushDirection, duration: TimeInterval = 0.2) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = kCATransitionPush
        transition.subtype = direction.coreAnimationConstant
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        layer.add(transition, forKey: nil)
    }
    
}
