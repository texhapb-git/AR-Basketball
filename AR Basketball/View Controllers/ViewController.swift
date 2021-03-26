//
//  ViewController.swift
//  Basketball Test
//
//  Created by Максим Иванов on 21.03.2021.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // MARK: - @IBOutlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var tipsLabel: UILabel!
    
    
    // MARK: - Properties
    let configuration = ARWorldTrackingConfiguration()
    
    private var isHoopAdded = false {
        didSet {
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set start tip
        tipsLabel.text = Tips.startTip.rawValue
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Detect vertical planes
        configuration.planeDetection = [.horizontal, .vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Private Methods
    
    private func getBallNode() -> SCNNode? {
        
        // Get current position to the ball
        guard let frame = sceneView.session.currentFrame else {
            return nil
        }
        
        // Get camera transform
        let cameraTransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTransform)
        
        // Ball geometry and color
        let ball = SCNSphere(radius: 0.125)
        let ballTexture: UIImage = #imageLiteral(resourceName: "basketball")
        ball.firstMaterial?.diffuse.contents = ballTexture
        
        // Ball node
        let ballNode = SCNNode(geometry: ball)
        
        
        // Calculate force matrix for pushing the ball
        let power = Float(5)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x, y, z)
        
        // Add physics
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode ))
        
        ballNode.physicsBody?.mass = 0.570
        
        // Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        
        // Assign camera position to ball
        ballNode.simdTransform = cameraTransform
        
        return ballNode
    }
    
    private func getHoopNode() -> SCNNode {
        
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        let hoopNode = scene.rootNode.clone()
        
        hoopNode.physicsBody = SCNPhysicsBody(
            type: .static,
            shape: SCNPhysicsShape(
                node: hoopNode,
                options: [
                    SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron
                ]
            )
        )
        
        return hoopNode
    }
    
    private func getPlaneNode(for plane: ARPlaneAnchor) -> SCNNode {
        
        let extent = plane.extent
        
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.blue
        
        // Create 75% transparent plane node
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        // Rotate plane
        planeNode.eulerAngles.x -= .pi / 2
        
        return planeNode
    }
    
    private func updatePlaneNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        // Change plane node center
        planeNode.simdPosition = anchor.center
        
        // Change plane size
        let extent = anchor.extent
        plane.width = CGFloat(extent.x)
        plane.height = CGFloat(extent.z)
        
    }

    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        DispatchQueue.main.async {
             self.tipsLabel.textColor = .white
             self.tipsLabel.text = Tips.placeHoop.rawValue
        }
        
        // Add hoop to the center of vertical plane
        node.addChildNode(getPlaneNode(for: planeAnchor))
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        // Update plane node
        updatePlaneNode(node, for: planeAnchor)
    }
    
    
    // MARK: - @IBActions
    
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        
        if isHoopAdded {
            
            guard let ballNode = getBallNode() else {
                return
            }
            
            tipsLabel.text = ""
            
            sceneView.scene.rootNode.addChildNode(ballNode)
            
        } else {
        
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {
                return
            }
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {
                return
            }
        
            // Get hoop none and set it coordinates
            let hoopNode = getHoopNode()
            hoopNode.simdTransform = result.worldTransform
            hoopNode.eulerAngles.x -= .pi / 2
            
            isHoopAdded = true
            sceneView.scene.rootNode.addChildNode(hoopNode)
            
            tipsLabel.textColor = .green
            tipsLabel.text = Tips.throwBall.rawValue
            
            
        }
        
    }
    

}

