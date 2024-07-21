//
//  GameViewController+Gestures.swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/23/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import SceneKit
import ARKit

extension ViewController{
    // add pan gesture recognizer to rotate 
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer){
        let scnView = recognizer.view as! SCNView
        
        // check what we tapped
        //let p = recognizer.location(in: scnView)
        //let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        
        //if let hit = hitResults.first, hit.node == sphere {
        
        //こちらのhitTestは[SCNHitTestResult]を返すもので非推奨となった関数とは別もの
        let hitResults = scnView.hitTest(recognizer.location(in: scnView), options: nil)
        //こちらが非推奨となった関数
//        guard let transform = scnView.hitTest(sender.location(in: scnView), types: .existingPlaneUsingExtent).first?.worldTransform else {
//            return
//        }
        let hit = hitResults.first
        print("hit start")
        if  hit?.node == sphere.childNode(withName:"JoinedObject", recursively: true) {
        //if hit?.node == sphere {
            print("hit ok")
            // retrieved the first clicked object
            touchedObject = sphere
            let worldTouch = simd_float3(hit!.worldCoordinates)
            let localTouch = simd_float3(hit!.localCoordinates)
        
            switch recognizer.state{
            case .began:
                updateQueue.async {
                    switch self.mode{
                    case .inertialApplePhysics:
                        print("inertialApplePhysics began")
                        self.touchedObject?.previousTouch = localTouch
                    default:
                        self.touchedObject?.previousTouch = worldTouch
                    }
                }
                
            case .changed:
                updateQueue.async {
                    if let touchedObject = self.touchedObject,
                        var previousTouch = touchedObject.previousTouch{
                        
                        switch self.mode{
                        case .quaternion  :
                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)

                            self.touchedObject?.rotate(from: previousTouch, to: currentTouch)
                            self.touchedObject?.previousTouch = worldTouch
                        case .inertialHomegrown:
                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)
                        
                            self.touchedObject?.applyTorque(from: previousTouch, to: currentTouch)
                            self.touchedObject?.previousTouch = worldTouch
                        case .inertialApplePhysics:
                            print("inertialApplePhysics changed")
                            let oldWorldPosition = hit?.node.simdConvertPosition(previousTouch, to: nil)
                            let newWorldPosition = hit?.node.simdConvertPosition(localTouch, to: nil)
                            
                            self.touchedObject?.previousTouch = localTouch
                            self.sphereAnchor.applyTorque(startLocation: oldWorldPosition!, endLocation: newWorldPosition!)
                            
                            break
                        }
                    }
                }
            case .ended:
                print("inertialApplePhysics end")
                clear()
            default: break
            }
            
        }else{
            clear()
        }
    }
    
    /// Called when finger left the object
    /// or pan gesture eneded.
    /// we want to set prevoiousTouch to nil
    /// and angular acceleration to zero
    internal func clear(){
        updateQueue.async {
            self.touchedObject?.previousTouch = nil
            self.touchedObject?.simplePhysicsBody?.angularAcceleration = simd_float3()
        }
    }
    
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer){
        print("ViewController+Gestures handlePinch start")
        if recognizer.numberOfTouches == 2 {
            let zoom = Float(recognizer.scale)
            if recognizer.state == .began {
                updateQueue.async {
                    self.previousScale = self.sphereAnchor.simdScale
                }
            } else if recognizer.state == .changed {
                let final = previousScale * zoom
                updateQueue.async {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.15
                    self.sphereAnchor.simdScale = final
                    SCNTransaction.commit()
                }
            }
        }
        print("ViewController+Gestures handlePinch end")
        
    }
    
    //Method called when tap
    @objc func handleTap(rec: UITapGestureRecognizer){
        print("ViewController+Gestures handleTap start")

        print("タップされました")
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: sceneView)
            print(location)
            
//            guard let query = sceneView.raycastQuery(from: location, allowing: .existingPlaneInfinite, alignment: .any) else {
//               return
//            }
//
//            let results = sceneView.session.raycast(query)
//            let hitTestResult = results.first
//            else {
//               print("No surface found")
////               return
//            }
        
//            let estimatedPlane: ARRaycastQuery.Target = .estimatedPlane
//            let estimatedPlane: ARRaycastQuery.Target = .existingPlaneInfinite
//            let alignment: ARRaycastQuery.TargetAlignment = .any
//
//            let query: ARRaycastQuery? = sceneView.raycastQuery(from: location,
//                                                            allowing: estimatedPlane,
//                                                           alignment: alignment)
//            let results = sceneView.session.raycast(query!)
//            let hitTestResult = results.first
//
            
//            if let nonOptQuery: ARRaycastQuery = query {
//
//                let result: [ARRaycastResult] = sceneView.session.raycast(nonOptQuery)
//
//                guard let rayCast: ARRaycastResult = result.first
//                else { return }
//
//                self.loadGeometry(rayCast)
//            }
            
            //let tappedNode = hits.first?.node
            //print(tappedNode as A	ny)
            //print(String("\(location.x)") + "---" +  String("\(location.y)") + "---" + String("\(tappedNode?.rotation.z)"))
            //let action = SCNAction.move(to: SCNVector3(location.x, location.y, CGFloat((tappedNode?.rotation.z)!)),duration: 1)
            
            // カメラ座標系で30cm前
//            let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -0.1)
            let infrontOfCamera = SCNVector3(x: 0, y: 0, z: -800)
            
            // カメラ座標系 -> ワールド座標系
            guard let cameraNode = sceneView.pointOfView else { return }
            print("cameraNode.x: " + String("\(cameraNode.position.x)"))
            print("cameraNode.y: " + String("\(cameraNode.position.y)"))
            print("cameraNode.z: " + String("\(cameraNode.position.z)"))

            let pointInWorld = cameraNode.convertPosition(infrontOfCamera, to: nil)
            print("pointInWorld.x: " + String("\(pointInWorld.x)"))
            print("pointInWorld.y: " + String("\(pointInWorld.y)"))
            print("pointInWorld.z: " + String("\(pointInWorld.z)"))

            // ワールド座標系 -> スクリーン座標系
            var screenPos = sceneView.projectPoint(pointInWorld)
            
            // スクリーン座標系で
            // x, yだけ指の位置に変更
            // zは変えない
            screenPos.x = Float(location.x)
            screenPos.y = Float(location.y)
            
            // ワールド座標に戻す
            let finalPosition = sceneView.unprojectPoint(screenPos)
            print("finalPosition.x: " + String("\(finalPosition.x)"))
            print("finalPosition.y: " + String("\(finalPosition.y)"))
            print("finalPosition.z: " + String("\(finalPosition.z)"))

            
            //4. Set The New Position
            let node = sceneView.scene.rootNode.childNode(withName:"JoinedObject", recursively: true)?.parent?.parent
            let action = SCNAction.move(to: finalPosition,duration: 2)
            node?.runAction(action)
        }
        print("ViewController+Gestures handleTap end")


    }
}
