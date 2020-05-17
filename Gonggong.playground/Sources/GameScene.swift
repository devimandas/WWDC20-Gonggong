import SpriteKit

public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //VIP VARIABLE
    let numberOfGonggong = 5
    let maxGonggongSpeed : UInt32 = 100
    var distance: CGFloat =  1.5
    
    var player: SKSpriteNode!
    var gonggong = [SKSpriteNode]()
    var gameOver = false
    var movingPlayer = false
    var offset: CGPoint!
    
    func positionWithin(range: CGFloat, containerSize:CGFloat) ->CGFloat {
        let partA = CGFloat(arc4random_uniform(100)) / 100.0
        let partB = (containerSize * (1.0 - range) * 0.5)
        let partC = (containerSize * range + partB)
        
        return partA * partC
    }
    
    func distanceFrom(posA: CGPoint, posB: CGPoint) ->CGFloat {
        let aSquared = (posA.x - posB.x) * (posA.x - posB.x)
        let bSquared = (posA.y - posB.y) * (posA.x - posB.y)
        return sqrt(aSquared + bSquared)
    }
    
    
    public override func didMove(to view: SKView) {
        distance /= 2.0
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.0
        physicsWorld.contactDelegate = self
        
        //background
        let bg = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "dalam laut 2.png")))
        bg.setScale(2.0)
        bg.zPosition = -10
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(bg)
        
        //player
        player = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "gonggong baik.png")), color: .clear, size: CGSize(width: size.width * 0.05, height: size.width * 0.05))
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        player.addCircle(radius: player.size.width * (0.5 + distance), edgeColor: .green, filled: true)
        addChild(player)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * (0.5 + distance))
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = Bitmasks.player
        player.physicsBody?.contactTestBitMask = Bitmasks.enemy
        
        //gonggong
        for _ in 1...numberOfGonggong {
            createGonggong()
        }
        
        
        for snail in gonggong {
            snail.physicsBody?.applyImpulse(CGVector(dx: CGFloat(arc4random_uniform(maxGonggongSpeed)) - (CGFloat(maxGonggongSpeed) * 0.5), dy: CGFloat(arc4random_uniform(maxGonggongSpeed)) - (CGFloat(maxGonggongSpeed) * 0.5)))
        }
        
        let infectedGonggong = gonggong[Int(arc4random_uniform(UInt32(gonggong.count)))]
        infectedGonggong.texture = SKTexture(image: #imageLiteral(resourceName: "gonggong jahat.png"))
        infectedGonggong.physicsBody?.categoryBitMask = Bitmasks.enemy
        (infectedGonggong.children.first as? SKShapeNode)?.strokeColor = .red
    }
    
    func createGonggong() {
        let snail = SKSpriteNode(texture: SKTexture(image: #imageLiteral(resourceName: "gonggong baik.png")), color: .clear, size: CGSize(width: size.width * 0.05, height: size.width * 0.05))
        snail.position = CGPoint(x: positionWithin(range: 0.8, containerSize: size.width), y: positionWithin(range: 0.8, containerSize: size.height))
        snail.addCircle(radius: player.size.width * (0.5 + distance), edgeColor: .lightGray, filled: false)
        
        while distanceFrom(posA: snail.position, posB: player.position) < snail.size.width * distance * 5 {
            snail.position = CGPoint(x: positionWithin(range: 0.8, containerSize: size.width), y: positionWithin(range: 0.8, containerSize: size.height))
        }
        
            addChild(snail)
        gonggong.append(snail)
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width * (0.5 + distance))
        snail.physicsBody?.affectedByGravity = false
        snail.physicsBody?.categoryBitMask = Bitmasks.uninfectedGonggong
        snail.physicsBody?.contactTestBitMask = Bitmasks.enemy
        snail.physicsBody?.friction = 0.0
        snail.physicsBody?.angularDamping = 0.0
        snail.physicsBody?.restitution = 1.1
        snail.physicsBody?.friction = 0.0
        snail.physicsBody?.allowsRotation = false
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver else {return}
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        let touchedNodes = nodes(at: touchLocation)
        
        for node in touchedNodes {
            if node == player {
                movingPlayer = true
                offset = CGPoint(x: touchLocation.x - player.position.x, y: touchLocation.y - player.position.y)
            }
        }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !gameOver && movingPlayer else {return}
        guard let touch = touches.first else {return}
        let touchLocation = touch.location(in: self)
        let newPlayerPosition = CGPoint(x: touchLocation.x - offset.x, y: touchLocation.y - offset.y)
        
        player.run(SKAction.move(to: newPlayerPosition, duration: 0.01)) //for smoothening
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movingPlayer = false
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == Bitmasks.uninfectedGonggong && contact.bodyB.categoryBitMask == Bitmasks.enemy {
            infect(snail: contact.bodyA.node as! SKSpriteNode)
        } else if contact.bodyB.categoryBitMask == Bitmasks.uninfectedGonggong && contact.bodyA.categoryBitMask == Bitmasks.enemy {
            infect(snail: contact.bodyB.node as! SKSpriteNode)
        } else if contact.bodyA.categoryBitMask == Bitmasks.player || contact.bodyB.categoryBitMask == Bitmasks.player {
            triggerGameOver()
        }
    } 
    
    func infect(snail:SKSpriteNode) {
        snail.texture = SKTexture(image: #imageLiteral(resourceName: "gonggong jahat.png"))
        snail.physicsBody?.categoryBitMask = Bitmasks.enemy
        (snail.children.first as? SKShapeNode)?.strokeColor = .red
    }
    
    func triggerGameOver() {
        gameOver = true
        
        player.texture = SKTexture(image: #imageLiteral(resourceName: "gonggong jahat.png"))
        (player.children.first as? SKShapeNode)?.strokeColor = .orange
        (player.children.first as? SKShapeNode)?.fillColor = .init(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.3)
        
        for snail in gonggong {
            snail.physicsBody?.velocity = .zero
        }
        
        let gameOverLbl = SKLabelNode(text: "YOU HAVE BEEN POISONED!")
        gameOverLbl.fontSize = 70.0
        gameOverLbl.position = CGPoint(x: frame.midX, y: frame.midY)
        gameOverLbl.zPosition = 3
        gameOverLbl.fontColor = .white
        addChild(gameOverLbl)
    }
}
