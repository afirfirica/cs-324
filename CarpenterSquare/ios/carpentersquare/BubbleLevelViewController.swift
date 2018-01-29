//
//  BubbleLevelViewController.swift
//  carpentersquare
//
//  Created by Administrator on 11/29/17.
//  Copyright © 2017 RedShepard. All rights reserved.
//

import UIKit
import CoreMotion

class BubbleLevelViewController: UIViewController {
    
    @IBOutlet weak var bubbleImageView: UIImageView!
    @IBOutlet weak var angleLabel: UILabel!
    
    @IBOutlet weak var bubbleImageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bubbleImageViewLeftConstraint: NSLayoutConstraint!
    
    var motionManager: CMMotionManager!
    
    let maxAngle: CGFloat = 25.0

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        bubbleImageViewLeftConstraint.constant = (self.view.bounds.width - bubbleImageView.bounds.size.width) * 0.5
        bubbleImageViewTopConstraint.constant = (self.view.bounds.height - bubbleImageView.bounds.size.height) * 0.5
        
        motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 0.3
        startDeviceMotionUpdate()
    }
    
    func startDeviceMotionUpdate() {
        motionManager.startDeviceMotionUpdates(to: .main) { (motion, error) in
            if let attitude = motion?.attitude {
                var angleX = CGFloat(attitude.roll * 180.0 / Double.pi)
                var angleY = CGFloat(attitude.pitch * 180.0 / Double.pi)
                
                if angleX > self.maxAngle {
                    angleX = self.maxAngle
                } else if angleX < -self.maxAngle {
                    angleX = -self.maxAngle
                }
                
                if angleY > self.maxAngle {
                    angleY = self.maxAngle
                } else if angleY < -self.maxAngle {
                    angleY = -self.maxAngle
                }
                
                let width = self.view.bounds.width - self.bubbleImageView.bounds.size.width
                let height = self.view.bounds.height - self.bubbleImageView.bounds.size.height
                
                let x = width * 0.5 + angleX * width * 0.5 / self.maxAngle
                let y = height * 0.5 + angleY * height * 0.5 / self.maxAngle
                
                UIView.animate(withDuration: 0.6, delay: 0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
                    self.bubbleImageViewLeftConstraint.constant = x
                    self.bubbleImageViewTopConstraint.constant = y
                    self.view.layoutIfNeeded()
                }, completion: nil)
                
                self.angleLabel.text = String.init(format: "%.1f°", max(fabs(angleX), fabs(angleY)))
                
            }
        }
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
