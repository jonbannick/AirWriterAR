//
//  ARDrawingViewController
//  Air Writer
//
//  Created by Jonathan Bannick on 10/11/17.
//  Copyright © 2017 Jonathan Bannick. All rights reserved.
//
import UIKit
import ARKit
import ColorSlider
import SwiftThicknessPicker
import Photos

class ARDrawingViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, SwiftThicknessPickerDelegate {
    
    private var drawingPoints = [SCNVector3]()
    var drawingNodes = [SCNNode]()
    var drawings = [[SCNNode]]()
    
    var videoImages = [UIImage]()
    
    var touchPos = CGPoint()
    
    var recording = false
    
    var videoURL: URL?
    
    var previousTime = 0.0
    
    let videoRenderer = VideoRenderer()
    
    var recordingTime = 0.0
    
    private var isTouching = false {
        didSet {
            //pen.isHidden = !isTouching
        }
    }
    override var prefersStatusBarHidden: Bool {
        return true
    }
    @IBOutlet var sceneView: ARSCNView!
    var statusLabel = UILabel()
    //var pen: UILabel!
    
    var colorSlider = ColorSlider()
    
    let thicknessPicker = SwiftThicknessPicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //setup UILabel
        
        statusLabel.frame = CGRect(x: 20, y: 40, width: view.frame.width - 40, height: 50)
        statusLabel.backgroundColor = UIColor.init(white: 0.2, alpha: 0.5)
        statusLabel.textAlignment = NSTextAlignment.center
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.masksToBounds = true
        statusLabel.textColor = UIColor.white
        view.addSubview(statusLabel)
        
        // Setup the color picker
        
        colorSlider.orientation = .horizontal
        colorSlider.previewEnabled = true
        
        colorSlider.frame = CGRect(x: 20, y: view.frame.height - 50, width: view.frame.width - 40, height: 40)
        
        //colorSlider = ColorSlider(orientation: .vertical, previewSide: .left)
        //colorSlider.frame = CGRectMake(0, 0, 12, 150)
        
        view.addSubview(colorSlider)
        
        //setup thickness picker
        thicknessPicker.delegate = self
        thicknessPicker.direction = SwiftThicknessPicker.PickerDirection.vertical
        thicknessPicker.minValue = 1
        thicknessPicker.maxValue = 100
        thicknessPicker.frame = CGRect(x: 5, y: colorSlider.frame.minY - 450, width: 40, height: 400)
        view.addSubview(thicknessPicker)
        
        sceneView.delegate = self
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.scene = SCNScene()
        
        statusLabel.text = "Wait..."
        //pen.isHidden = true
        
        
        let iconViewWidth = CGFloat(60)
        let iconViewRadius = iconViewWidth / 2
        let iconViewMargin = CGFloat(20)
        let iconWidth = iconViewWidth * 0.5
        let iconMargin = (iconViewWidth - iconWidth) / 2
        
        let iconListViewHeight = (iconViewWidth * 4) + (iconViewMargin * 3)
        let iconListView = UIView(frame: CGRect(x: view.frame.width - iconViewWidth - iconViewMargin, y: colorSlider.frame.minY - iconListViewHeight - iconViewMargin - iconViewMargin, width: iconViewWidth, height: iconListViewHeight))
        
        view.addSubview(iconListView)
        
        //last drawing delete button
        let goBackButton = UIButton(frame: CGRect(x: 0, y: 0, width: iconViewWidth, height: iconViewWidth))
        goBackButton.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
        goBackButton.addTarget(self, action: #selector(reset), for: .touchUpInside)
        goBackButton.layer.cornerRadius = iconViewRadius
        goBackButton.layer.masksToBounds = true
        
        let goBackIcon = UIImageView(frame: CGRect(x: iconMargin, y: iconMargin, width: iconWidth, height: iconWidth))
        goBackIcon.image = UIImage(named: "undogray")
        goBackButton.addSubview(goBackIcon)
        
        iconListView.addSubview(goBackButton)
        
        
        //delete all button
        let deleteAllButton = UIButton(frame: CGRect(x: 0, y: goBackButton.frame.maxY + iconViewMargin, width: iconViewWidth, height: iconViewWidth))
        deleteAllButton.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
        deleteAllButton.addTarget(self, action: #selector(resetAll), for: .touchUpInside)
        deleteAllButton.layer.cornerRadius = iconViewRadius
        deleteAllButton.layer.masksToBounds = true
        
        let deleteIcon = UIImageView(frame: CGRect(x: iconMargin, y: iconMargin, width: iconWidth, height: iconWidth))
        deleteIcon.image = UIImage(named: "trash")
        deleteAllButton.addSubview(deleteIcon)
        
        iconListView.addSubview(deleteAllButton)
        
        //snapshot button
        let snapshotButton = UIButton(frame: CGRect(x: 0, y: deleteAllButton.frame.maxY + iconViewMargin, width: iconViewWidth, height: iconViewWidth))
        snapshotButton.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
        snapshotButton.addTarget(self, action: #selector(snapshot), for: .touchUpInside)
        snapshotButton.layer.cornerRadius = iconViewRadius
        snapshotButton.layer.masksToBounds = true
        
        let snapshotIcon = UIImageView(frame: CGRect(x: iconMargin, y: iconMargin, width: iconWidth, height: iconWidth))
        snapshotIcon.image = UIImage(named: "camera")
        snapshotButton.addSubview(snapshotIcon)
        
        iconListView.addSubview(snapshotButton)
        
        //record button
        let recordButton = UIButton(frame: CGRect(x: 0, y: snapshotButton.frame.maxY + iconViewMargin, width: iconViewWidth, height: iconViewWidth))
        recordButton.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
        recordButton.addTarget(self, action: #selector(record), for: .touchUpInside)
        recordButton.layer.cornerRadius = iconViewRadius
        recordButton.layer.masksToBounds = true
        
        let recordIcon = UIImageView(frame: CGRect(x: iconMargin, y: iconMargin, width: iconWidth, height: iconWidth))
        recordIcon.image = UIImage(named: "video")
        recordButton.addSubview(recordIcon)
        
        iconListView.addSubview(recordButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        sceneView.session.run()
        thicknessPicker.currentValue = 10
        isTouching = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - Private
    
    @objc private func reset() {
        if(drawings.count > 0){
            for node in drawings.last!{
                node.removeFromParentNode()
            }
            drawings.removeLast()
        }
    }
    @objc func resetAll(){
        if(drawings.count > 0){
            for drawing in drawings{
                for node in drawing{
                    node.removeFromParentNode()
                }
            }
            drawings.removeAll()
        }
    }
    @objc func snapshot(){
        
        let image = sceneView.snapshot()
        
        let flashView = UIView(frame: view.frame)
        flashView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.0)
        view.addSubview(flashView)
        
        UIView.animate(withDuration: 0.2, animations: {
            flashView.backgroundColor = UIColor.init(white: 1.0, alpha: 1.0)
        }) { finished in
            UIView.animate(withDuration: 0.2, animations: {
                flashView.backgroundColor = UIColor.init(white: 1.0, alpha: 0.0)
            }, completion: { finished in
                flashView.removeFromSuperview()
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "ImageController") as! ImageController
                vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                vc.image = image
                self.present(vc, animated: true, completion: nil)
            })
        }
    }
    @objc func record(sender: UIButton){
        let recordButton = sender
        if(!recording){
            recordingTime = 0.0
            recording = true
            UIView.animate(withDuration: 1, delay: 0, options: [.repeat,.autoreverse,.allowUserInteraction], animations: {
                recordButton.backgroundColor = UIColor.init(red: 0.8, green: 0.4, blue: 0.4, alpha: 1)
            }) { finished in
                
            }

            var options = VideoRendererOptions()
            options.videoSize = CGSize(width: view.frame.width, height: view.frame.height)
            options.fps = 30
            
            
            //let videoRenderer = VideoRenderer()
            videoRenderer.render(
                scene: sceneView.scene,
                withOptions: options,
                until: {
                    return !self.recording
                    //return self.rotations >= self.totalRotations
            },andThen: {
                outputURL, cleanup in
                print("Video file at: ".appending(outputURL.path))
                self.videoURL = outputURL
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "VideoController") as! VideoController
                //vc.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
                vc.videoURL = self.videoURL
                self.present(vc, animated: true, completion: nil)
                //cleanup()
                /*PHPhotoLibrary.shared().performChanges({ () -> Void in
                    
                    let createAssetRequest: PHAssetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)!
                    createAssetRequest.placeholderForCreatedAsset
                    
                })
                { (success, error) -> Void in
                    if success {
                        print("succ")
                        //cleanup()
                    }
                    else {
                        print("no succ")
                        print(error)
                    }
                }*/
            })
        }else{
            recordButton.layer.removeAllAnimations()
            recordButton.backgroundColor = UIColor.init(white: 0.5, alpha: 0.5)
            recording = false
            print(recording)
        }
    }
    private func isReadyForDrawing(trackingState: ARCamera.TrackingState) -> Bool {
        switch trackingState {
        case .normal:
            return true
        default:
            return false
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //print(time - previousTime)
        if(recording){
            recordingTime += (time - previousTime)
            videoRenderer.timerDaDaDoo = recordingTime
        }
        //print("!@#$%^")
        //print(time - previousTime)
        previousTime = time
        
        guard isTouching else {return}
        guard let currentDrawing = drawingPoints.last else {return}
        
        
        let currentPoint = getNodePoint()
        
        let previousPoint = drawingPoints.last
        
        let startSphere = SCNSphere(radius: 0.0001 * CGFloat(thicknessPicker.currentValue))
        let startSphereNode = SCNNode(geometry: startSphere)
        startSphere.firstMaterial?.diffuse.contents = colorSlider.color
        startSphereNode.geometry = startSphere
        startSphereNode.position = previousPoint!
        sceneView.scene.rootNode.addChildNode(startSphereNode)
        drawingNodes.append(startSphereNode)
        
        let endSphere = SCNSphere(radius: 0.0001 * CGFloat(thicknessPicker.currentValue))
        let endSphereNode = SCNNode(geometry: endSphere)
        endSphere.firstMaterial?.diffuse.contents = colorSlider.color
        endSphereNode.geometry = endSphere
        endSphereNode.position = currentPoint
        sceneView.scene.rootNode.addChildNode(endSphereNode)
        drawingNodes.append(endSphereNode)
        
        let twoPointsNode = SCNNode()
        sceneView.scene.rootNode.addChildNode(twoPointsNode.buildLineInTwoPointsWithRotation(
            from: previousPoint!, to: currentPoint, radius: 0.0001 * CGFloat(thicknessPicker.currentValue), color: colorSlider.color))
        
        drawingNodes.append(twoPointsNode)
        
        drawingPoints.append(currentPoint)
        
    }
    
    // MARK: - ARSessionObserver
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("\(self.classForCoder)/\(#function), error: " + error.localizedDescription)
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("trackingState: \(camera.trackingState)")
        
        let state = camera.trackingState
        let isReady = isReadyForDrawing(trackingState: state)
        statusLabel.text = isReady ? "Touch the screen to draw." : "Wait. " + state.description
    }
    
    func getNodePoint() -> SCNVector3{
        let cameraPos = sceneView.session.currentFrame?.camera.transform
        
        let posMatrix = SCNMatrix4(cameraPos!)
        
        let screenBounds = UIScreen.main.bounds
        //let center = CGPoint(x: screenBounds.midX, y: screenBounds.midY)
        let center = touchPos
        let centerVec3 = SCNVector3Make(Float(center.x), Float(center.y), 0.998)
        
        return sceneView.unprojectPoint(centerVec3)

    }
    
    // MARK: - Touch Handlers
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let frame = sceneView.session.currentFrame else {return}
        guard isReadyForDrawing(trackingState: frame.camera.trackingState) else {return}
        
        let touch = touches.first!
        touchPos = touch.location(in: view)
        
        drawingPoints.append(getNodePoint())
        
        //sceneView.scene.rootNode.addChildNode(drawingNode)
        
        statusLabel.text = "Keep Drawing!"
        
        isTouching = true
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        touchPos = touch.location(in: view)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
        drawings.append(drawingNodes)
        drawingPoints.removeAll()
        drawingNodes.removeAll()
        statusLabel.text = "Touch the screen to draw."
    }
    
    // MARK: - Actions
    func valueChanged(_ value: Int) {
        
    }
}
extension SCNNode {
    
    func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
        let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
        if length == 0 {
            return SCNVector3(0.0, 0.0, 0.0)
        }
        
        return SCNVector3( iv.x / length, iv.y / length, iv.z / length)
        
    }
    
    func buildLineInTwoPointsWithRotation(from startPoint: SCNVector3,
                                          to endPoint: SCNVector3,
                                          radius: CGFloat,
                                          color: UIColor) -> SCNNode {
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = startPoint
            return self
            
        }
        
        let cyl = SCNCylinder(radius: radius, height: l)
        cyl.firstMaterial?.diffuse.contents = color
        
        self.geometry = cyl
        
        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                            (endPoint.z-startPoint.z)/2.0)
        
        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)
        
        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = Float(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = Float(av_normalized.x) // x' * sin(angle/2)
        let q2 = Float(av_normalized.y) // y' * sin(angle/2)
        let q3 = Float(av_normalized.z) // z' * sin(angle/2)
        
        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3
        
        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0
        
        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0
        
        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0
        
        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
        return self
    }
}
