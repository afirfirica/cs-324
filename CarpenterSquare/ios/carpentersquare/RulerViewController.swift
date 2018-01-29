//
//  RulerViewController.swift
//  carpentersquare
//
//  Created by Administrator on 11/30/17.
//  Copyright © 2017 RedShepard. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import PKHUD

class RulerViewController: UIViewController {
    
    enum Step: Int {
        case ready = 0
        case drawing
        case finished
    }

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var indicatorImageView: UIImageView!
    @IBOutlet weak var aButton: UIButton!
    @IBOutlet weak var bButton: UIButton!
    @IBOutlet weak var resultLabel: PaddingLabel!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBOutlet weak var aButtonCenterXConstraint: NSLayoutConstraint!
    @IBOutlet weak var aButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bButtonWidthConstraint: NSLayoutConstraint!
    
    var currentStep: Step = .ready
    var line: LineNode?
    var cameraNode: SCNNode!
    var lines: [LineNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // scene view
        cameraNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(cameraNode)

        // top description label
        let descString = "Measure for Side A and Side B"
        let descAttributedString = NSMutableAttributedString.init(string: descString, attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 20), NSAttributedStringKey.foregroundColor: UIColor.white])
        let aRange = (descString as NSString).range(of: "A")
        descAttributedString.addAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 22)], range: aRange)
        let bRange = (descString as NSString).range(of: "B")
        descAttributedString.addAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 22)], range: bRange)
        descriptionLabel.attributedText = descAttributedString
        
        // bottom buttons
        aButton.layer.borderColor = UIColor.white.cgColor
        bButton.layer.borderColor = UIColor.white.cgColor
        resultLabel.layer.borderColor = UIColor.border.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        restartSession()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        sceneView.session.pause()
    }
    
    @IBAction func back(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onA(_ sender: Any) {
        if lines.count == 0 {
            if line == nil {
                let startPos = worldPositionFromScreenPosition(CGPoint.init(x: indicatorImageView.center.x, y: indicatorImageView.frame.origin.y), objectPos: nil)
                if let p = startPos.position {
                    line = LineNode(startPos: p, sceneV: sceneView, cameraNode: cameraNode)
                }
            } else {
                lines.append(line!)
                line = nil
                
                if let lineA = lines.last {
                    line = LineNode(startPos: lineA.endNode.position, sceneV: sceneView, cameraNode: cameraNode)
                }
            }
            
            currentStep = .drawing
            updateUI()
        }
    }
    
    @IBAction func onB(_ sender: Any) {
        if lines.count == 1 {
            lines.append(line!)
            line = nil
            
            if let lineA = lines.first, let lineB = lines.last {
                let lineC = LineNode(startPos: lineB.endNode.position, sceneV: sceneView, cameraNode: cameraNode, lineColor: UIColor.line)
                _ = lineC.updatePosition(pos: lineA.startNode.position, camera: sceneView.session.currentFrame?.camera)
                lines.append(lineC)
                if let scnText = lineC.textNode.geometry as? SCNText, let text = scnText.string as? String {
                    resultLabel.text = text
                }
            }
            
            currentStep = .finished
            updateUI()
        }
    }
    
    @IBAction func redo(_ sender: Any) {
        if currentStep == .drawing {
            if line != nil {
                line?.removeFromParent()
                line = nil
            }
            
            if lines.count > 0, let lineA = lines.last {
                line = LineNode(startPos: lineA.startNode.position, sceneV: sceneView, cameraNode: cameraNode)
                lineA.removeFromParent()
                lines.removeLast()
            } else {
                currentStep = .ready
            }
            
            updateUI()
        }
    }
    
    @IBAction func clear(_ sender: Any) {
        line?.removeFromParent()
        line = nil
        lines.forEach { (line) in
            line.removeFromParent()
        }
        lines.removeAll()
        
        currentStep = .ready
        updateUI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}

extension RulerViewController {
    
    func restartSession() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        line?.removeFromParent()
        line = nil
        lines.forEach { (line) in
            line.removeFromParent()
        }
        lines.removeAll()
        
        indicatorImageView.tintColor = UIColor.alert
    }

    func updateLineNode() {
        let startPos = self.worldPositionFromScreenPosition(CGPoint.init(x: indicatorImageView.center.x, y: indicatorImageView.frame.origin.y), objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 && line == nil {
                indicatorImageView.tintColor = UIColor.alert
                return
            }
            indicatorImageView.tintColor = UIColor.fine
            _ = self.line?.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera)
        }
        
        guard self.sceneView.session.currentFrame != nil else {
            return
        }
        let camera = self.sceneView.session.currentFrame!.camera
        let cameraPos = SCNVector3.positionFromTransform(camera.transform)
        cameraNode.position = cameraPos
    }
    
    func updateUI() {
        descriptionLabel.isHidden = line != nil || lines.count > 0
        
        var aButtonCenterXOffset: CGFloat
        var aButtonWidth: CGFloat
        var bButtonWidth: CGFloat
        var aButtonBackgroundColor: UIColor
        var bButtonBackgroundColor: UIColor
        var aButtonAlpha: CGFloat
        var bButtonAlpha: CGFloat
        var aButtonFontSize: CGFloat
        var bButtonFontSize: CGFloat
        var aButtonTitleColor: UIColor
        var bButtonTitleColor: UIColor
        var resultLabelAlpha: CGFloat
        switch currentStep {
        case .ready:
            aButtonCenterXOffset = 0
            aButtonWidth = 42
            bButtonWidth = 34
            aButtonBackgroundColor = UIColor.clear
            bButtonBackgroundColor = UIColor.clear
            aButtonAlpha = 1.0
            bButtonAlpha = 0.52
            aButtonFontSize = 20
            bButtonFontSize = 14
            aButtonTitleColor = UIColor.white
            bButtonTitleColor = UIColor.white
            resultLabelAlpha = 0
        case .drawing:
            if lines.count == 0 {
                aButtonCenterXOffset = 0
                aButtonWidth = 42
                bButtonWidth = 34
                aButtonBackgroundColor = UIColor.white
                bButtonBackgroundColor = UIColor.clear
                aButtonAlpha = 1.0
                bButtonAlpha = 0.52
                aButtonFontSize = 20
                bButtonFontSize = 14
                aButtonTitleColor = UIColor.dark
                bButtonTitleColor = UIColor.white
            } else {
                aButtonCenterXOffset = aButton.center.x - bButton.center.x
                aButtonWidth = 34
                bButtonWidth = 42
                aButtonBackgroundColor = UIColor.clear
                bButtonBackgroundColor = UIColor.white
                aButtonAlpha = 0.52
                bButtonAlpha = 1.0
                aButtonFontSize = 14
                bButtonFontSize = 20
                aButtonTitleColor = UIColor.white
                bButtonTitleColor = UIColor.dark
            }
            resultLabelAlpha = 0
        case .finished:
            aButtonCenterXOffset = (aButton.center.x - bButton.center.x) * 2
            aButtonWidth = 34
            bButtonWidth = 34
            aButtonBackgroundColor = UIColor.clear
            bButtonBackgroundColor = UIColor.clear
            aButtonAlpha = 0.52
            bButtonAlpha = 0.52
            aButtonFontSize = 14
            bButtonFontSize = 14
            aButtonTitleColor = UIColor.white
            bButtonTitleColor = UIColor.white
            resultLabelAlpha = 1
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, options: [UIViewAnimationOptions.beginFromCurrentState], animations: {
            self.aButtonCenterXConstraint.constant = aButtonCenterXOffset
            self.aButtonWidthConstraint.constant = aButtonWidth
            self.aButton.layer.cornerRadius = aButtonWidth / 2
            self.aButton.alpha = aButtonAlpha
            self.aButton.titleLabel?.font = UIFont.systemFont(ofSize: aButtonFontSize)
            self.aButton.backgroundColor = aButtonBackgroundColor
            self.aButton.setTitleColor(aButtonTitleColor, for: .normal)
            
            self.bButtonWidthConstraint.constant = bButtonWidth
            self.bButton.layer.cornerRadius = bButtonWidth / 2
            self.bButton.alpha = bButtonAlpha
            self.bButton.titleLabel?.font = UIFont.systemFont(ofSize: bButtonFontSize)
            self.bButton.backgroundColor = bButtonBackgroundColor
            self.bButton.setTitleColor(bButtonTitleColor, for: .normal)
            
            self.resultLabel.alpha = resultLabelAlpha
            
            self.view.layoutIfNeeded()
        }, completion: { (finished) in
            let enabled = self.line != nil || self.lines.count > 0
            self.undoButton.isEnabled = enabled && self.currentStep != .finished
            self.clearButton.isEnabled = enabled
        })
    }
}

extension RulerViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateLineNode()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let tips = camera.trackingState.presentationString
        switch camera.trackingState {
        case .notAvailable:
            HUD.show(.label(tips))
        case .normal:
            HUD.hide()
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                HUD.flash(.label(tips),delay:0.5)
                break
            case .insufficientFeatures,.initializing:
                HUD.show(.label(tips))
                break
            }
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        let err = error as? ARError
        if err != nil {
            HUD.show(.label(err!.code.presentationString))
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
}

extension RulerViewController {
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 50.0)
        
        // Filter feature points
        let featureCloud = sceneView.fliterWithFeatures(highQualityfeatureHitTestResults)
        
        if featureCloud.count >= 3 {
            let warpFeatures = featureCloud.map({ (feature) -> NSValue in
                return NSValue(scnVector3: feature)
            })
            
            // Plane estimation based on feature points
            let detectPlane = planeDetectWithFeatureCloud(featureCloud: warpFeatures)
            
            var planePoint = SCNVector3Zero
            if detectPlane.x != 0 {
                planePoint = SCNVector3(detectPlane.w/detectPlane.x,0,0)
            }else if detectPlane.y != 0 {
                planePoint = SCNVector3(0,detectPlane.w/detectPlane.y,0)
            }else {
                planePoint = SCNVector3(0,0,detectPlane.w/detectPlane.z)
            }
            
            let ray = sceneView.hitTestRayFromScreenPos(position)
            let crossPoint = planeLineIntersectPoint(planeVector: SCNVector3(detectPlane.x,detectPlane.y,detectPlane.z), planePoint: planePoint, lineVector: ray!.direction, linePoint: ray!.origin)
            if crossPoint != nil {
                return (crossPoint, nil, false)
            }else{
                return (featureCloud.average!, nil, false)
            }
        }
        
        if !featureCloud.isEmpty {
            featureHitTestPosition = featureCloud.average
            highQualityFeatureHitTestResult = true
        }else if !highQualityfeatureHitTestResults.isEmpty {
            featureHitTestPosition = highQualityfeatureHitTestResults.map { (featureHitTestResult) -> SCNVector3 in
                return featureHitTestResult.position
                }.average
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if infinitePlane || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    func planeDetectWithFeatureCloud(featureCloud: [NSValue]) -> SCNVector4 {
        let result = PlaneDetector.detectPlane(withPoints: featureCloud)
        return result
    }
    
    /// The intersection points are calculated from the points and vectors on the line and the points on the plane and the normal vector
    ///
    /// - Parameters:
    ///   - planeVector: Flat law vector
    ///   - planePoint: On the plane
    ///   - lineVector: Straight line vector
    ///   - linePoint: A little straight
    /// - Returns: Intersection
    func planeLineIntersectPoint(planeVector: SCNVector3 , planePoint: SCNVector3, lineVector: SCNVector3, linePoint: SCNVector3) -> SCNVector3? {
        let vpt = planeVector.x*lineVector.x + planeVector.y*lineVector.y + planeVector.z*lineVector.z
        if vpt != 0 {
            let t = ((planePoint.x-linePoint.x)*planeVector.x + (planePoint.y-linePoint.y)*planeVector.y + (planePoint.z-linePoint.z)*planeVector.z)/vpt
            let cross = SCNVector3Make(linePoint.x + lineVector.x*t, linePoint.y + lineVector.y*t, linePoint.z + lineVector.z*t)
            if (cross-linePoint).length() < 5 {
                return cross
            }
        }
        return nil
    }
}
