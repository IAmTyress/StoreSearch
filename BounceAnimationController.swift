//
//  BounceAnimationController.swift
//  StoreSearch
//
//  Created by Russ Rosaura on 8/18/21.
//  Copyright © 2021 Malysh Tim. All rights reserved.
//

import UIKit

class BounceAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.4
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to), let toView = transitionContext.view(forKey: UITransitionContextViewKey.to) {
            
            let containerView = transitionContext.containerView
            toView.frame = transitionContext.finalFrame(for: toViewController)
            containerView.addSubview(toView)
            toView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
            
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: .calculationModeCubic, animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.001) {
                    toView.alpha = 0.0
                    toView.transform = CGAffineTransform(scaleX: 0.0, y: 0.0)
                    toView.center = containerView.center
                }
                UIView.addKeyframe(withRelativeStartTime: 0.001, relativeDuration: 0.333) {
                    toView.alpha = 1
                    toView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.334, relativeDuration: 0.333) {
                    toView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.667, relativeDuration: 0.333) {
                    toView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }) { finished in
                transitionContext.completeTransition(finished)
            }
        }
    }
    
}
