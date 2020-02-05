//
//  CardMotionView.swift
//  RappiCard
//
//  Created by Nicolas Battelli on 05/02/2020.
//  Copyright © 2020 Nicolas Battelli. All rights reserved.
//

import Foundation
import SceneKit
import CoreMotion


final class CardMotionView: XibView {
    
    let motionManager = CMMotionManager()
    var currentDeviceAttitude: CMAttitude?
    var initialAttitude: CMAttitude?
    var initialNodeOrientation: SCNQuaternion?
    
    @IBOutlet var sceneView: SCNView! {
        willSet {
            newValue.allowsCameraControl = true
        }
    }
    
    var rappiNode: SCNNode?
    var cameraNode: SCNNode?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sceneSetup()
        motionSetup()
    }
    
    private func sceneSetup() {
        sceneView.delegate = self
        sceneView.isPlaying = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        let scene = SCNScene()
        
        let cardSize = calculateCardSize()
        let rappiGeometry = SCNPlane(width: cardSize.width, height: cardSize.height)
        rappiGeometry.firstMaterial?.diffuse.contents = "rappi_logo"
        rappiGeometry.firstMaterial?.isDoubleSided = true
        
        let rappiNode = SCNNode(geometry: rappiGeometry)
        scene.rootNode.addChildNode(rappiNode)
        rappiNode.position = SCNVector3(10, -6, -10)
        initialNodeOrientation = rappiNode.orientation
        
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3Make(0, 0, 50)
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.scene = scene
        
        self.rappiNode = rappiNode
        self.cameraNode = cameraNode
    }
    
    private func calculateCardSize() -> CGSize {
        let viewSize = frame.size
        
        if viewSize.width >= viewSize.height {
            let height = viewSize.height * 0.1
            let width = (height * 2) / 3
            return CGSize(width: width, height: height)
        } else {
            let width = viewSize.width * 0.1
            let height = (width * 3) / 2
            return CGSize(width: width, height: height)
        }
    }
    
    private func motionSetup() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1/30.0
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: OperationQueue(), withHandler: { (deviceMotion, error) in
                guard let data = deviceMotion else { return }
                if self.initialAttitude == nil {
                    self.initialAttitude = data.attitude
                }
                
                self.currentDeviceAttitude = data.attitude
            })
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        if(touch.view == self.sceneView){
            let viewTouchLocation: CGPoint = touch.location(in: sceneView)
            guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                return
            }
            print("results", "\(result)")
            let touchPlaneNode = rappiNode
            if touchPlaneNode == result.node {
                createParticle(coordinate: result.worldCoordinates)
            }

        }
    }
    
    func createParticle(coordinate: SCNVector3) {
        let particleSystem = SCNParticleSystem(named: "fire", inDirectory: nil)
        particleSystem?.emissionDuration = 2
        particleSystem?.loops = false
        particleSystem?.particleSize = 0.1
        particleSystem?.particleColor = UIColor.blue
        
        let systemNode = SCNNode()
        systemNode.addParticleSystem(particleSystem!)
        systemNode.position = coordinate
        systemNode.position.z = 20
        sceneView.scene!.rootNode.addChildNode(systemNode)
    }
    
}

extension CardMotionView: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        if let q = currentDeviceAttitude?.quaternion,
            let i = initialAttitude?.quaternion,
            let rappiNode = self.rappiNode {
            
            //GLKQuaternion current position
            let gkq = GLKQuaternionMakeWithAngleAndAxis(GLKMathDegreesToRadians(30), 0, 0, 1)
            
            //GLKQuaternion initial position
            let gki = GLKQuaternionMake(Float(-i.x), Float(i.y), Float(i.z), Float(i.w))
                
            //GLKQuaternion angle
            let gqAngle = GLKQuaternionMake(Float(q.x), Float(q.y), 0, Float(q.w))
            
            let zp = GLKQuaternionMultiply(gkq, gki)
            let gkr = GLKQuaternionMultiply(zp, gqAngle)
            
            let limitedX = Float.maximum(-0.1,(Float.minimum(0.1, gkr.x)))
            let limitedY = Float.maximum(-0.1,(Float.minimum(0.1, gkr.y)))
            let limitedZ = Float.maximum(0.15,(Float.minimum(0.35, gkr.z)))
            let limitedW = Float.maximum(0.9,(Float.minimum(1, gkr.w)))
            
            //SCNQuaternion result
            let qr = SCNQuaternion(limitedX, limitedY, limitedZ, limitedW)
            
            rappiNode.orientation = qr
        }
    }
}
