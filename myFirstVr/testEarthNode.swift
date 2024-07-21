//
//  testEarthNode.swift
//  myFirstVr
//
//  Created by ring ring on 2021/10/03.
//

import SceneKit

class TestEarthNode: SCNNode {

    override init() {
        super.init()
        
        self.geometry = SCNSphere(radius: 0.5)
        self.geometry?.firstMaterial?.diffuse.contents = UIImage(named:"Diffuse")
        self.geometry?.firstMaterial?.specular.contents = UIImage(named:"Specular")
        self.geometry?.firstMaterial?.emission.contents = UIImage(named:"Emission")
        self.geometry?.firstMaterial?.normal.contents = UIImage(named:"Normal")
        
        self.geometry?.firstMaterial?.shininess = 50
        
        //let action = SCNAction.rotate(by: 360 * CGFloat(Double.pi / 180), around: SCNVector3(x:0, y:1, z:0), duration: 8)
        //let repeatAction = SCNAction.repeatForever(action)
        //self.runAction(repeatAction)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    
}
