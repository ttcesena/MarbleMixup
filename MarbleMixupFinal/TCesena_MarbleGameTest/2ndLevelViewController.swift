

import UIKit
import SceneKit

class LevelTwoViewController: UIViewController {
    let categoryTrigger = 2
    var sceneView:SCNView!
    var scene:SCNScene!
    var marbleNode:SCNNode!
    var followCameraNode:SCNNode!
    var triggerNode:SCNNode!
    var motion = MotionHelper()
    var motionForce = SCNVector3(0,0,0)
    
    var sounds:[String:SCNAudioSource] = [:]
    override func viewDidLoad(){
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    
    func setupScene(){
        sceneView = (self.view as! SCNView)
        sceneView.delegate = self
        //sceneView.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/Level2.scn")
        sceneView.scene = scene
        
        scene.physicsWorld.contactDelegate = self
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.numberOfTouchesRequired = 1
        
        tapRecognizer.addTarget(self,action: #selector(LevelTwoViewController.sceneViewTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
    }
    func setupNodes(){
        marbleNode = scene.rootNode.childNode(withName: "marble", recursively: true)!
        marbleNode.physicsBody?.contactTestBitMask = categoryTrigger
        followCameraNode = scene.rootNode.childNode(withName: "followCamera", recursively: true)!
    }
    func setupSounds(){
        let jumpSound = SCNAudioSource(fileNamed: "MarbleJump.wav")!
        let victorySound = SCNAudioSource(fileNamed: "VictoryTrigger.wav")!
        let loseSound = SCNAudioSource(fileNamed: "GameOverTrigger.wav")!
        jumpSound.load()
        victorySound.load()
        loseSound.load()
        jumpSound.volume = 0.5
        victorySound.volume = 0.3
        loseSound.volume = 0.3
        
        sounds["jump"] = jumpSound
        sounds["victory"] = victorySound
        sounds["lose"] = loseSound
        
        let backgroundMusic = SCNAudioSource(fileNamed: "MarbleLevelMusic.mp3")!
        backgroundMusic.volume = 0.1
        backgroundMusic.loops = true
        backgroundMusic.load()
        
        let musicPlayer = SCNAudioPlayer(source: backgroundMusic)
        marbleNode.addAudioPlayer(musicPlayer)
        
        
    }
    
    @objc func sceneViewTapped (recognizer:UITapGestureRecognizer){
        let location = recognizer.location(in:sceneView)
        let hitResults = sceneView.hitTest(location,options:nil)
        
        if hitResults.count > 0 {
            let result = hitResults.first
            if let node = result?.node{
                if node.name == "marble"{
                    let jumpSound = sounds["jump"]!
                    marbleNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
                    marbleNode.physicsBody?.applyForce(SCNVector3(x: 0, y:2,z:0), asImpulse: true)
                }
            }
        }
    }
    override var shouldAutorotate: Bool{
        return false
    }
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    
}

extension LevelTwoViewController : SCNSceneRendererDelegate{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let marble = marbleNode.presentation
        let marblePosition = marble.position
        
        let targetPosition = SCNVector3(x: marblePosition.x,y: marblePosition.y + 5,z: marblePosition.z + 5)
        var cameraPosition = followCameraNode.position
        
        let camDamping:Float = 0.3
        let xComponent = cameraPosition.x * (1-camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1-camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1-camDamping) + targetPosition.z * camDamping
        cameraPosition = SCNVector3(x: xComponent, y: yComponent, z: zComponent)
        followCameraNode.position = cameraPosition
        
        motion.getAccelerometerData{(x,y,z) in
            self.motionForce = SCNVector3(x: x * 0.05, y:0, z: (y + 0.8) * -0.05)
        }
        marbleNode.physicsBody?.velocity += motionForce
    }
}
extension LevelTwoViewController: SCNPhysicsContactDelegate{
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        var contactNode:SCNNode!
        
        if contact.nodeA.name == "marble" {
            contactNode = contact.nodeB
        }else {
            contactNode = contact.nodeA
        }
        if contactNode.physicsBody?.categoryBitMask == categoryTrigger && contactNode.name == "GameOverTrigger"{
            //contactNode.isHidden = true
            //print (contactNode)
            let loseSound = sounds["lose"]!
            marbleNode.runAction(SCNAction.playAudio(loseSound, waitForCompletion: false))
            //musicPlayer.stop()
            let storyBoard = UIStoryboard(name:"Main",bundle:nil)
            let gameOverController = storyBoard.instantiateViewController(withIdentifier: "GameOverVC")
            self.present(gameOverController,animated:true,completion:nil)
            //print (contactNode)
        }
        if contactNode.physicsBody?.categoryBitMask == categoryTrigger && contactNode.name == "WinTrigger"{
            //contactNode.isHidden = true
            //print (contactNode)
            let victorySound = sounds["victory"]!
            marbleNode.runAction(SCNAction.playAudio(victorySound, waitForCompletion: false))
            //musicPlayer.stop()
            let storyBoard = UIStoryboard(name:"Main",bundle:nil)
            let WinController = storyBoard.instantiateViewController(withIdentifier: "WinVC")
            self.present(WinController,animated:true,completion:nil)
            //print (contactNode)
        }
    }
    
}
