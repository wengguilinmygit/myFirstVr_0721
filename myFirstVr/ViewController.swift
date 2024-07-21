//
//  ViewController.swift
//  myFirstVr
//
//  Created by ring ring on 2021/09/28.
//

import UIKit
import SceneKit
import ARKit
import QuartzCore


enum RotationMode: Int{
    case quaternion, inertialHomegrown, inertialApplePhysics
}


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var changeRotate: UIButton!
    
    //Store The Rotation Of The CurrentNode
    var currentAngleY: Float = 0.0
    var currentAngleX: Float = 0.0
    var originalRotation: SCNVector3? = nil

    //Not Really Necessary But Can Use If You Like
    var isRotating = false
    
    var isXRotating = true
    
    var isBall = true
    
    let sphere = EarthNode()
    /// parent object for sphere
    let sphereAnchor = SCNNode()
    
    var touchedObject: EarthNode?
    
    var previousScale = simd_float3()
    
    let updateQueue = DispatchQueue(label: "update queue")
    
    /// get rotation mode from mode selector control
    var mode: RotationMode = .quaternion
    
    
    
    
    override func viewDidLoad() {
        NSLog("viewDidLoad"+" start")
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //let scene = SCNScene(named: "art.scnassets/cutTest_v1.0_20210922.scn" )!
        let scene = SCNScene(named: "art.scnassets/cutTest_v1.0_20211003.scn" )!
        //let scene = SCNScene(named: "art.scnassets/testearth.scn" )!
        
        // create a new scene
//        let scene = SCNScene()
//        // create and add a camera to the scene
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        scene.rootNode.addChildNode(cameraNode)
//
//        // place the camera
//        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        
//        // create and add a light to the scene
//        let lightNode = SCNNode()
//        lightNode.light = SCNLight()
//        lightNode.light!.type = .omni
//        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
//        scene.rootNode.addChildNode(lightNode)
//
        // create and add an ambient light to the scene
//        let ambientLightNode = SCNNode()
//        ambientLightNode.light = SCNLight()
//        ambientLightNode.light!.type = .ambient
//        ambientLightNode.light!.color = UIColor.darkGray
//        scene.rootNode.addChildNode(ambientLightNode)
        
        // create a sphere that we are going to rotate
        let radius = Float(0.1524) //6 inches
        let mass = Float(0.8) // 0.8 kg
        // hollow sphere with 0.8kg and 12 inches diameter
        sphere.simplePhysicsBody = SimplePhysicsBody(mass: mass, radius: radius)
        
        
        // add Apple physicsBody for comparison
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: sphere, options: [:]))
        physicsBody.isAffectedByGravity = false
        sphereAnchor.physicsBody = physicsBody
        sphere.physicsBody?.mass = CGFloat(mass)
        sphere.name="sphere"
        sphere.addChildNode(SCNScene(named:  "art.scnassets/cutTest_v1.0_20211003.dae")!.rootNode.childNode(withName:"JoinedObject", recursively: true)!)
        
        //cutTest_v1.0_plane_20211016
//        sphere.addChildNode(SCNScene(named:  "art.scnassets/cutTest_v1.0_plane_20211016.dae")!.rootNode.childNode(withName:"JoinedObject", recursively: true)!)
        
        sphereAnchor.addChildNode(sphere)
        sphereAnchor.name="sphereAnchor"
        //sphereAnchor.addChildNode(sphere.childNode(withName:"JoinedObject", recursively: true)!)
    
        scene.rootNode.addChildNode(sphereAnchor)
        
        //sceneView.delegate = self
        // so that we keep receiving calls to updateAtTime
        sceneView.isPlaying = true
        
        // set the scene to the view
        sceneView.scene = scene
        
        // allows the user to manipulate the camera
        sceneView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        sceneView.debugOptions = [
            .showPhysicsShapes,
        ]
        
        // configure the view
        //sceneView.backgroundColor = UIColor.black
        
        // add pan gesture recognizer to rotate 
        print("ViewController start handlePan ")
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panRecognizer)
        
        // add pinch gesture recognizer to zoom . for zoom out ,zoom in
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
        
        //Create TapGesture Recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        //Add recognizer to sceneview
        sceneView.addGestureRecognizer(tap)
        
        
        
        //add target method for mod selection change
        //self.modeSelector.addTarget(self, action: #selector(rotationModeChanged), for: .valueChanged)
                
//        cameraNode.x: -0.23000336
//        cameraNode.y: 0.07249451
//        cameraNode.z: 392.887

        //カメラの座標を固定すると、Objectの座標はカメラの相対位置になり、Object固定座標におくのはできなくなる？
//        let cameraNode = SCNNode()
//        cameraNode.camera = SCNCamera()
//        cameraNode.position = SCNVector3(x:-0.23000336, y: 0.07249451, z:-1000)
//        scene.rootNode.addChildNode(cameraNode)
        
        /*


        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 2)
        scene.rootNode.addChildNode(lightNode)
        
        //let earthNode = EarthNode()
        //scene.rootNode.addChildNode(earthNode)
        
        let node = scene.rootNode.childNodes.filter({ $0.name == "JoinedObject" })[0]
        node.scale=SCNVector3Make(Float(0.001), Float(0.001), Float(0.001))
        node.eulerAngles=SCNVector3Make(Float(-161.826 ), Float(-60.874), Float(-112.924))
         */
         
        
        
        // Set the scene to the view
        // sceneView.autoenablesDefaultLighting=true
        //sceneView.allowsCameraControl=true
        // /////////////sceneView.scene = scene
        //sceneView.frame(width:UIScreen.main.bounds.width,height:UIScreen.main.bounds.height)
        
        /**/
//        let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
//        node?.scale=SCNVector3Make(Float(0.001), Float(0.001), Float(0.001))
//        //node.eulerAngles=SCNVector3Make(Float(-161.826 ), Float(-60.874), Float(-112.924))
//
//        // カメラ座標系で30cm前
//        let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -0.3)
//        // カメラ座標系 -> ワールド座標系
//        guard let cameraNode = sceneView.pointOfView else { return }
//        let pointInWorld = cameraNode.convertPosition(infrontOfCamera, to: nil)
//        // ワールド座標系 -> スクリーン座標系
//        var screenPos = sceneView.projectPoint(pointInWorld)
//        // スクリーン座標系で
//        // x, yだけ指の位置に変更
//        // zは変えない
//        screenPos.x = Float(140)
//        screenPos.y = Float(330)
//        // ワールド座標に戻す
//        let finalPosition = sceneView.unprojectPoint(screenPos)
//        node?.position=finalPosition
//        //node.position=SCNVector3(x: 0, y: 0, z: 0)
//
        
        //节点在我放置它时面对相机然后将它保持在这里（并且能够移动）
        //if let rotate = sceneView.session.currentFrame?.camera.transform {
        //    node.simdTransform = rotate
        //}
         
        
        //SCNNodeのインスタンスのconstraintsプロパティに追加するだけで、カメラ目線を実現できます。
        //let billboardConstraint = SCNBillboardConstraint()
        //Y軸の回転はこの制約を加えない様にします。
        //billboardConstraint.freeAxes = SCNBillboardAxis.Y
        //node.constraints = [billboardConstraint]
        
        /**/
        //Create TapGesture Recognizer
//        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
//        //Add recognizer to sceneview
//        sceneView.addGestureRecognizer(tap)
//
//
//        //sceneを移動させます。
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(doRotation3))
//        self.sceneView.addGestureRecognizer(panGesture)
//
//        //sceneを回転させます。
//        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(doRotation))
//        self.sceneView.addGestureRecognizer(rotationGesture)
//
//        //sceneをズームイン/ズームアウトさせる。
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(doPinch))
//        self.sceneView.addGestureRecognizer(pinchGesture)
        
            NSLog("viewDidLoad"+" end")
        
    }
    
    
    override var shouldAutorotate: Bool {
        NSLog("shouldAutorotate"+" start")
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        NSLog("prefersStatusBarHidden"+" start")
        return true
        
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        NSLog("supportedInterfaceOrientations"+" start")
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    @objc func rotationModeChanged(sender: UISegmentedControl){
        NSLog("rotationModeChanged"+" start")
        self.mode = RotationMode(rawValue: sender.selectedSegmentIndex) ?? .quaternion
        self.clear()
        self.touchedObject?.simplePhysicsBody?.angularVelocity = simd_float3()
        
        if self.mode == .inertialApplePhysics{
            sphereAnchor.physicsBody?.resetTransform()
        }else{
            // we applied torque to sphereAnchor, so reset it
            // and rotate the sphere to compensate
            updateQueue.async {
                self.sphereAnchor.physicsBody?.clearAllForces()
                let anchorOrientation = self.sphereAnchor.presentation.simdOrientation
                self.sphereAnchor.simdOrientation = simd_quatf()
                self.sphere.simdOrientation = anchorOrientation *  self.sphere.simdOrientation
            }
        }
        NSLog("rotationModeChanged"+" end")
    }
    
//    @objc func handlePan(_ recognizer: UIPanGestureRecognizer){
//        let scnView = recognizer.view as! SCNView
//
//        // check what we tapped
//        let p = recognizer.location(in: scnView)
//        let hitResults = scnView.hitTest(p, options: [:])
//        // check that we clicked on at least one object
//        let nodeObj = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
//        if let hit = hitResults.first, hit.node == nodeObj {
//            // retrieved the first clicked object
//            var touchedObject = nodeObj
//            let worldTouch = simd_float3(hit.worldCoordinates)
//            let localTouch = simd_float3(hit.localCoordinates)
//
//            switch recognizer.state{
//            case .began:
//                updateQueue.async {
//                    switch self.mode{
//                    case .inertialApplePhysics:
//                        touchedObject?.previousTouch = localTouch
//                    default:
//                        touchedObject?.previousTouch = worldTouch
//                    }
//                }
//
//            case .changed:
//                updateQueue.async {
//                    if let touchedObject = self.touchedObject,
//                        var previousTouch = touchedObject.previousTouch{
//
//                        switch self.mode{
//                        case .quaternion  :
//                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
//                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)
//
//                            touchedObject?.rotate(from: previousTouch, to: currentTouch)
//                            touchedObject?.previousTouch = worldTouch
//                        case .inertialHomegrown:
//                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
//                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)
//
//                            touchedObject?.applyTorque(from:
//                                previousTouch, to: currentTouch)
//                            touchedObject?.previousTouch = worldTouch
//                        case .inertialApplePhysics:
//                            let oldWorldPosition = hit.node.simdConvertPosition(previousTouch, to: nil)
//                            let newWorldPosition = hit.node.simdConvertPosition(localTouch, to: nil)
//
//                            touchedObject?.previousTouch = localTouch
//                            self.sphereAnchor.applyTorque(startLocation: oldWorldPosition, endLocation: newWorldPosition)
//
//                            break
//                        }
//                    }
//                }
//            case .ended:
//                clear()
//            default: break
//            }
//
//        }else{
//            clear()
//        }
//    }
//
//    /// Called when finger left the object
//    /// or pan gesture eneded.
//    /// we want to set prevoiousTouch to nil
//    /// and angular acceleration to zero
//    internal func clear(){
//        updateQueue.async {
//            self.touchedObject?.previousTouch = nil
//            self.touchedObject?.simplePhysicsBody?.angularAcceleration = simd_float3()
//        }
//    }
    
    //sceneを移動させます。
    @objc private func doPan(sender: UIPanGestureRecognizer) {
        NSLog("doPan"+" start")
        if !isRotating{
            if sender.state == .ended {
                let location: CGPoint = sender.location(in: sceneView)
                print(location)
                
                //let tappedNode = hits.first?.node
                //print(tappedNode as Any)
                //print(String("\(location.x)") + "---" +  String("\(location.y)") + "---" + String("\(tappedNode?.rotation.z)"))
                //let action = SCNAction.move(to: SCNVector3(location.x, location.y, CGFloat((tappedNode?.rotation.z)!)),duration: 1)
                
                // カメラ座標系で30cm前
                let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -0.3)
                
                // カメラ座標系 -> ワールド座標系
                guard let cameraNode = sceneView.pointOfView else { return }
                let pointInWorld = cameraNode.convertPosition(infrontOfCamera, to: nil)
                // ワールド座標系 -> スクリーン座標系
                var screenPos = sceneView.projectPoint(pointInWorld)
                
                // スクリーン座標系で
                // x, yだけ指の位置に変更
                // zは変えない
                screenPos.x = Float(location.x)
                screenPos.y = Float(location.y)
                
                // ワールド座標に戻す
                let finalPosition = sceneView.unprojectPoint(screenPos)
                
                //4. Set The New Position
                let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
                let action = SCNAction.move(to: finalPosition,duration: 1)
                node?.runAction(action)
            }

            }
        NSLog("doPinch"+" start")
        }
    
    //sceneを回転させます。
    @objc private func doRotation3(sender: UIPanGestureRecognizer) {
        NSLog("doRotation3"+" start")
        //let node = self.sceneView.scene.rootNode
        
        let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
        let translation = sender.translation(in: sender.view!)
        
        
//        var newAngleY = -(Float)(translation.x)*(Float)(Double.pi)/180.0
//        newAngleY += currentAngleY
//        node?.eulerAngles.y = newAngleY
//        if(sender.state == .ended) {
//            currentAngleY = newAngleY
//            print("Called the handlePan method")
//            print("translation.x:"+String("\(translation.x)"))
//            print("eulerAngles.y:"+String("\(node?.eulerAngles.y)"))
//            print("translation.y:"+String("\(translation.y)"))
//            print("eulerAngles.x:"+String("\(node?.eulerAngles.x)"))
//        }
        
        /*
         */
        if(isXRotating){
            var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
            newAngleY += currentAngleY
            node?.eulerAngles.y = newAngleY
            if(sender.state == .ended) {
                currentAngleY = newAngleY
                print("Called the handlePan method")
                print("translation.x:"+String("\(translation.x)"))
                print("eulerAngles.y:"+String("\(node?.eulerAngles.y)"))
                print("translation.y:"+String("\(translation.y)"))
                print("eulerAngles.x:"+String("\(node?.eulerAngles.x)"))
            }
        }
        else{
            var newAngleX = -(Float)(translation.y)*(Float)(Double.pi)/180.0
            newAngleX += currentAngleX
            node?.eulerAngles.x = newAngleX
            if(sender.state == .ended) {
                currentAngleX = newAngleX
                print("Called the handlePan method")
                print("translation.x:"+String("\(translation.x)"))
                print("eulerAngles.y:"+String("\(node?.eulerAngles.y)"))
                print("translation.y:"+String("\(translation.y)"))
                print("eulerAngles.x:"+String("\(node?.eulerAngles.x)"))
            }
        }
        NSLog("doRotation3"+" end")
        
        

        
    }
    
    //sceneを回転させます。
    @objc private func doRotation2(sender: UIPanGestureRecognizer) {
        NSLog("doRotation2"+" start")
        //let node = self.sceneView.scene.rootNode
        
        print("Called the handlePan method")
        let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
        let translation = sender.translation(in: sender.view!)
        let pan_x = Float(translation.x)
        let pan_y = Float(-translation.y)
        let anglePan = sqrt(pow(pan_x,2)+pow(pan_y,2))*(Float)(Double.pi)/180.0
        var rotationVector = SCNVector4()
        rotationVector.x = -pan_y
        rotationVector.y = pan_x
        rotationVector.z = 0
        rotationVector.w = anglePan
        node!.rotation = rotationVector
        if(sender.state == .ended) {
            let currentPivot = node!.pivot
            let changePivot = SCNMatrix4Invert(node!.transform)
            node!.pivot = SCNMatrix4Mult(changePivot, currentPivot)
            node!.transform = SCNMatrix4Identity
        }
        NSLog("doRotation2"+" end")
        
    }
    
    
    //sceneを回転させます。
    @objc private func doRotation(sender: UIRotationGestureRecognizer) {
        NSLog("doRotation"+" start")
        //let node = self.sceneView.scene.rootNode
        let node = sceneView.scene.rootNode.childNodes.filter({ $0.name == "JoinedObject" })[0]
        
        let location = sender.location(in: self.sceneView)


        switch sender.state {
            case .began:
                originalRotation = node.eulerAngles
            case .changed:
                guard var originalRotation = originalRotation
                else {
                    return
                }
                originalRotation.y -= Float(sender.rotation)
                node.eulerAngles = originalRotation
            default:
                originalRotation = nil
        }
        NSLog("doRotation"+" end")
        
    }
    
    //sceneをズームイン/ズームアウトさせる。
    @objc private func doPinch(gesture: UIPinchGestureRecognizer) {
        NSLog("doPinch"+" start")
        let scale = Float(gesture.scale)
        //let node = self.sceneView.scene.rootNode
        
        let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
        //let node = sceneView.scene.rootNode.childNodes.filter({ $0.name == "JoinedObject" })[0]
        //print(node as Any)
        switch gesture.state {
        case .changed:
            //ノードのスケールを拡大・縮小
            if scale > 1.000000000 {
                let action = SCNAction.scale(by: CGFloat(1.02), duration: 0.1)
                node?.runAction(action)
                NSLog("ノードのスケールを拡大")
            } else {
                let action = SCNAction.scale(by: CGFloat(0.98), duration: 0.1)
                node?.runAction(action)
                NSLog("ノードのスケールを縮小")
            }
            
        default:
            NSLog("not action")
        }
        NSLog("doPinch"+" end")
    }


    
    override func viewWillAppear(_ animated: Bool) {
        NSLog("viewWillAppear"+" start")

        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // ARAROrientationTrackingConfiguration
        //let configuration = AROrientationTrackingConfiguration()

        // Enable horizontal plane detection
        //configuration.planeDetection = .horizontal
        // show Feature Points
        //sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints
                                  //,ARSCNDebugOptions.showCameras
                                  //,ARSCNDebugOptions.showCreases
                                  //,ARSCNDebugOptions.showWorldOrigin
        //                         ]
        
        //let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
        //node?.scale=SCNVector3Make(Float(0.01), Float(0.01), Float(0.01))
        //node?.position=SCNVector3Make(Float(0), Float(0), Float(0))
        
        // Run the view's session
        sceneView.session.run(configuration)
        NSLog("viewWillAppear"+" end")

    }
    
    //When we enable horizontal plane detection, ARKit calls the renderer(_: didAdd node:, for anchor:) delegate method automatically whenever
    //it detects a new horizontal plane and also adds a new node for it. We receive the anchor of each detected flat surface, which will be
    //of type ARPlaneAnchor.
    
    //ARAnchor are used for tracking the real-world positions and orientations of real or simulated objects relative to the camera.
    //ARPlaneAnchor represents a planar surface in the world, defined using X and Z coordinates, where Y is the plane’s normal.
    
    //ARPlaneAnchor represents a planar surface in the world, defined using X and Z coordinates, where Y is the plane’s normal.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        NSLog("renderer"+" start")

       
         if let planeAnchor = anchor as? ARPlaneAnchor {
            
             let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
             plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.75)

             let planeNode = SCNNode(geometry: plane)
             planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.x, planeAnchor.center.z)
             planeNode.eulerAngles.x = -.pi / 2
             
             node.addChildNode(planeNode)
             
         }
        NSLog("renderer"+" end")

     }
    
    //ARKit monitors the environment and updates the previously detected anchors. We can get these updates by implementing the renderer(_:,
    //didUpdate node:, for anchor:) delegate method.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        NSLog("renderer"+" start")
        if let planeAnchor = anchor as? ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane {
            plane.width = CGFloat(planeAnchor.extent.x)
            plane.height = CGFloat(planeAnchor.extent.z)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        }
        NSLog("renderer"+" end")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NSLog("viewWillDisappear"+" start")
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        NSLog("viewWillDisappear"+" end")
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        NSLog("viewWillDisappear"+" start")

        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        NSLog("viewWillDisappear"+" start")

        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        NSLog("viewWillDisappear"+" start")

        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    //button istouchDown
    @IBAction func douchDown(_ sender: Any) {
//        let alert = UIAlertView()
//        alert.title = "Swiftでメッセージ"
//        alert.message = "SwiftでUIAlertViewを使ってメッセージ表示"
//        alert.addButton(withTitle: "OK")
//        alert.show()
        if (self.changeRotate.currentTitle=="平面"){
            isBall=false
            self.changeRotate.setTitle("球体", for: .normal)
        }else{
            isBall=true
            self.changeRotate.setTitle("平面", for: .normal)
        }
        
        //isBallの設定値より地球の表示型を変更する。
        changeObjectType()
        
    }
    
    //isBallの設定値より地球の表示型を変更する。
    func changeObjectType(){
        if isBall {
            //地球のボール型を表示する。
            //sceneView.scene.rootNode.removeChildren(in: sceneView.scene.rootNode.childNode(withName:"sphere", recursively: true))
            let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
            node?.removeFromParentNode()
            
            let sphereNodeForAdd = sceneView.scene.rootNode.childNode(withName:"sphere", recursively: true)
            sphereNodeForAdd?.addChildNode(SCNScene(named:  "art.scnassets/cutTest_v1.0_20211003.dae")!.rootNode.childNode(withName:"JoinedObject", recursively: true)!)
            
        }   else if !isBall {
            //地球の平面型を表示する。
            let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)
            node?.removeFromParentNode()
            
            let sphereNodeForAdd = sceneView.scene.rootNode.childNode(withName:"sphere", recursively: true)
            sphereNodeForAdd?.addChildNode(SCNScene(named:  "art.scnassets/cutTest_v1.0_plane_20211016.dae")!.rootNode.childNode(withName:"JoinedObject", recursively: true)!)
        }
        movetoInitPosition()
    }
    
    func movetoInitPosition(){
                
        // カメラ座標系で30cm前
        let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -10)
        
        // カメラ座標系 -> ワールド座標系
        guard let cameraNode = sceneView.pointOfView else { return }
        let pointInWorld = cameraNode.convertPosition(infrontOfCamera, to: nil)
        print("pointInWorld.x: " + String("\(pointInWorld.x)"))
        print("pointInWorld.y: " + String("\(pointInWorld.y)"))
        print("pointInWorld.z: " + String("\(pointInWorld.z)"))

        // ワールド座標系 -> スクリーン座標系
        var screenPos = sceneView.projectPoint(pointInWorld)
        
        // スクリーン座標系で
        // x, yだけ指の位置に変更
        // zは変えない
        screenPos.x = Float(0)
        screenPos.y = Float(0)
        
        // ワールド座標に戻す
        let finalPosition = sceneView.unprojectPoint(screenPos)
        
        //4. Set The New Position
        let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)?.parent?.parent
        let action = SCNAction.move(to: finalPosition,duration: 1)
        node?.runAction(action)
    }
    
}
