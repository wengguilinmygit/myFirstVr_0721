import UIKit
import SceneKit
import ARKit

// 枚举定义旋转模式
enum RotationMode: Int {
    case quaternion, inertialHomegrown, inertialApplePhysics
}

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var changeRotate: UIButton!
    
    // 记录当前旋转角度
    var currentAngleY: Float = 0.0
    var currentAngleX: Float = 0.0
    var originalRotation: SCNVector3? = nil
    var isRotating = false
    var isXRotating = true
    var isBall = true
    
    // 创建地球节点和锚点节点
    let sphere = EarthNode()
    let sphereAnchor = SCNNode()
    var touchedObject: EarthNode?
    var previousScale = simd_float3()
    
    // 更新队列
    let updateQueue = DispatchQueue(label: "updateQueue")
    var mode: RotationMode = .quaternion
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 设置ARSCNView的代理和显示统计信息
        sceneView.delegate = self
        sceneView.showsStatistics = true
        
        // 加载场景文件并初始化地球节点
        let scene = SCNScene(named: "art.scnassets/cutTest_v1.0_20211003.scn")!
        setupSphere(in: scene)
        
        // 启动SceneKit场景
        sceneView.isPlaying = true
        sceneView.scene = scene
        sceneView.allowsCameraControl = false
        sceneView.debugOptions = [.showPhysicsShapes]
        
        // 添加手势识别器
        addGestureRecognizers()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }
    
    // 初始化地球节点
    private func setupSphere(in scene: SCNScene) {
        let radius = Float(0.1524)
        let mass = Float(0.8)
        
        // 设置简单物理属性
        sphere.simplePhysicsBody = SimplePhysicsBody(mass: mass, radius: radius)
        
        // 设置物理体
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: sphere, options: [:]))
        physicsBody.isAffectedByGravity = false
        sphereAnchor.physicsBody = physicsBody
        sphere.physicsBody?.mass = CGFloat(mass)
        sphere.name = "sphere"
        
        // 加载子节点
        if let joinedObjectNode = SCNScene(named: "art.scnassets/cutTest_v1.0_20211003.dae")?.rootNode.childNode(withName: "JoinedObject", recursively: true) {
            sphere.addChildNode(joinedObjectNode)
        }
        
        // 将地球节点添加到锚点节点，并添加到场景根节点
        sphereAnchor.addChildNode(sphere)
        sphereAnchor.name = "sphereAnchor"
        scene.rootNode.addChildNode(sphereAnchor)
    }
    
    // 添加手势识别器
    private func addGestureRecognizers() {
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(panRecognizer)
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        sceneView.addGestureRecognizer(pinchRecognizer)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        sceneView.addGestureRecognizer(tap)
    }
    
    // 旋转模式改变处理
    @objc func rotationModeChanged(sender: UISegmentedControl) {
        self.mode = RotationMode(rawValue: sender.selectedSegmentIndex) ?? .quaternion
        clear()
        touchedObject?.simplePhysicsBody?.angularVelocity = simd_float3()
        
        if self.mode == .inertialApplePhysics {
            sphereAnchor.physicsBody?.resetTransform()
        } else {
            updateQueue.async {
                self.sphereAnchor.physicsBody?.clearAllForces()
                let anchorOrientation = self.sphereAnchor.presentation.simdOrientation
                self.sphereAnchor.simdOrientation = simd_quatf()
                self.sphere.simdOrientation = anchorOrientation * self.sphere.simdOrientation
            }
        }
    }
    
    // 处理平移手势
    @objc private func doPan(sender: UIPanGestureRecognizer) {
        if !isRotating {
            if sender.state == .ended {
                let location = sender.location(in: sceneView)
                let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -0.3)
                guard let cameraNode = sceneView.pointOfView else { return }
                let pointInWorld = cameraNode.convertPosition(infrontOfCamera, to: nil)
                var screenPos = sceneView.projectPoint(pointInWorld)
                screenPos.x = Float(location.x)
                screenPos.y = Float(location.y)
                let finalPosition = sceneView.unprojectPoint(screenPos)
                
                if let node = sceneView.scene.rootNode.childNode(withName: "JoinedObject", recursively: true) {
                    let action = SCNAction.move(to: finalPosition, duration: 1)
                    node.runAction(action)
                }
            }
        }
    }
    
    // 处理旋转手势
    @objc private func doRotation3(sender: UIPanGestureRecognizer) {
        guard let node = sceneView.scene.rootNode.childNode(withName: "JoinedObject", recursively: true) else { return }
        let translation = sender.translation(in: sender.view!)
        
        if isXRotating {
            let newAngleY = Float(translation.x) * Float(Double.pi) / 180.0 + currentAngleY
            node.eulerAngles.y = newAngleY
            if sender.state == .ended {
                currentAngleY = newAngleY
            }
        } else {
            let newAngleX = -Float(translation.y) * Float(Double.pi) / 180.0 + currentAngleX
            node.eulerAngles.x = newAngleX
            if sender.state == .ended {
                currentAngleX = newAngleX
            }
        }
    }
    
    // 处理捏合手势
    @objc private func doPinch(gesture: UIPinchGestureRecognizer) {
        guard let node = sceneView.scene.rootNode.childNode(withName: "JoinedObject", recursively: true) else { return }
        let scale = Float(gesture.scale)
        
        switch gesture.state {
        case .changed:
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.1
            node.scale = SCNVector3(scale, scale, scale)
            SCNTransaction.commit()
        default:
            break
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 启动AR会话
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    // 渲染器回调，当添加节点时调用
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            // 创建平面节点并添加到场景中
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.75)
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3Make(planeAnchor.center.x, planeAnchor.center.x, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
            
            node.addChildNode(planeNode)
        }
    }
    
//    // 处理点击手势
//    @objc func handleTap(rec: UITapGestureRecognizer) {
//        // 点击手势处理逻辑
//    }
//    
    // 清除状态
//    private func clear() {
//        updateQueue.async {
//            self.touchedObject?.previousTouch = nil
//            self.touchedObject?.simplePhysicsBody?.angularAcceleration = simd_float3()
//        }
//    }
}
