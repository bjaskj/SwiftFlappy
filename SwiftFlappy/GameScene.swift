//
//  GameScene.swift
//  SwiftFlappy
//
//  Created by Bjarte Skjørestad on 09/08/14.
//  Copyright (c) 2014 Bjarte Skjørestad. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var bird = SKSpriteNode()
    var skyColor = SKColor()
    var groundTextureHeight = CGFloat()
    var verticalPipeGap = 130.0
    var pipeTexture1 = SKTexture()
    var pipeTexture2 = SKTexture()
    var movePipesAndRemove = SKAction()
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    var moving = SKNode()
    var pipes = SKNode()
    var canRestart = false
    
    var scoreLabelNode = SKLabelNode()
    var score = NSInteger()
    
    override func didMoveToView(view: SKView) {
        setupMoving()
        setupGravity()
        setupSky()
        setupBird()
        setupGround()
        setupSkyline()
        setupPipes()
        setupScore()
    }
    
    func setupMoving() {
        self.addChild(moving)
    }
    
    func setupGravity() {
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        self.physicsWorld.contactDelegate = self
    }
    
    func setupSky() {
        skyColor = SKColor(red: 113.0/255.0, green: 197.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
    }
    
    func setupBird() {
        var birdTexture1 = SKTexture(imageNamed: "Bird1")
        birdTexture1.filteringMode = .Nearest
        var birdTexture2 = SKTexture(imageNamed: "Bird2")
        birdTexture2.filteringMode = .Nearest
        
        var animation = SKAction.animateWithTextures([birdTexture1, birdTexture2], timePerFrame: 0.2)
        var flap = SKAction.repeatActionForever(animation)
        
        bird = SKSpriteNode(texture: birdTexture1)
        bird.position = CGPoint(x: self.frame.size.width / 2.8, y: CGRectGetMidY(self.frame))
        bird.runAction(flap)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody.dynamic = true
        bird.physicsBody.allowsRotation = false
        
        bird.physicsBody.categoryBitMask = birdCategory
        bird.physicsBody.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody.contactTestBitMask = worldCategory | pipeCategory
        
        moving.addChild(bird)
    }
    
    func setupGround() {
        var groundTexture = SKTexture(imageNamed: "Ground")
        groundTexture.filteringMode = .Nearest
        groundTextureHeight = groundTexture.size().height
        
        var moveGroundSprite = SKAction.moveByX(-groundTexture.size().width, y: 0, duration: NSTimeInterval(0.01 * groundTexture.size().width))
        
        var resetGroundSprite = SKAction.moveByX(groundTexture.size().width, y: 0, duration: 0.0)
        
        var moveGroundSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveGroundSprite, resetGroundSprite]))
        
        for var i:CGFloat = 0; i < 2 + self.frame.size.width / (groundTexture.size().width); ++i {
            var sprite = SKSpriteNode(texture: groundTexture)
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2)
            sprite.runAction(moveGroundSpritesForever)
            moving.addChild(sprite)
        }
        
        var dummyGround = SKNode()
        dummyGround.position = CGPointMake(0, groundTexture.size().height / 2)
        dummyGround.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height))
        dummyGround.physicsBody.dynamic = false
        dummyGround.physicsBody.categoryBitMask = worldCategory
        moving.addChild(dummyGround)
    }
    
    func setupSkyline() {
        var skylineTexture = SKTexture(imageNamed: "Skyline")
        skylineTexture.filteringMode = .Nearest
        
        var moveSkylineSprite = SKAction.moveByX(-skylineTexture.size().width, y: 0.0, duration: NSTimeInterval(0.1 * skylineTexture.size().width))
        
        var resetSkylineSprite = SKAction.moveByX(skylineTexture.size().width, y: 0.0, duration: 0.0)
        
        var moveSkylineSpritesForever = SKAction.repeatActionForever(SKAction.sequence([moveSkylineSprite, resetSkylineSprite]))
        
        for var i:CGFloat = 0; i < 2 + self.frame.size.width / (skylineTexture.size().width); ++i {
            var sprite = SKSpriteNode(texture: skylineTexture)
            sprite.zPosition = -20
            sprite.position = CGPointMake(i * sprite.size.width, sprite.size.height / 2 + groundTextureHeight)
            sprite.runAction(moveSkylineSpritesForever)
            moving.addChild(sprite)
        }
    }
    
    func setupPipes() {
        moving.addChild(pipes)
        
        pipeTexture1 = SKTexture(imageNamed: "Pipe1")
        pipeTexture1.filteringMode = .Nearest
        pipeTexture2 = SKTexture(imageNamed: "Pipe2")
        
        var distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTexture1.size().width)
        var movePipes = SKAction.moveByX(-distanceToMove, y: 0.0, duration: NSTimeInterval(0.01 * distanceToMove))
        
        var removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        var spawn = SKAction.runBlock({ () in self.spawnPipes() })
        var delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        var spawnThenDelay = SKAction.sequence([spawn, delay])
        var spawnThenDelayForEver = SKAction.repeatActionForever(spawnThenDelay)
        self.runAction(spawnThenDelayForEver)
    }
    
    func spawnPipes() {
        pipeTexture2.filteringMode = .Nearest
        
        var pipePair = SKNode()
        pipePair.position = CGPointMake(self.frame.width + pipeTexture1.size().width * 2.0, 0)
        pipePair.zPosition = -10
        
        var height = UInt32(self.frame.height / 3)
        var y = arc4random() % height
        
        var pipe1 = SKSpriteNode(texture: pipeTexture1)
        pipe1.position = CGPointMake(0.0, CGFloat(y))
        pipe1.physicsBody = SKPhysicsBody(rectangleOfSize: pipe1.size)
        pipe1.physicsBody.dynamic = false
        pipe1.physicsBody.categoryBitMask = pipeCategory
        pipe1.physicsBody.contactTestBitMask = birdCategory
        pipePair.addChild(pipe1)
        
        var pipe2 = SKSpriteNode(texture: pipeTexture2)
        pipe2.position = CGPointMake(0.0, CGFloat(y) + pipe1.size.height + CGFloat(verticalPipeGap))
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipe2.size)
        pipe2.physicsBody.dynamic = false
        pipe2.physicsBody.categoryBitMask = pipeCategory
        pipe2.physicsBody.contactTestBitMask = birdCategory
        pipePair.addChild(pipe2)
        
        var contactNode = SKNode()
        contactNode.position = CGPointMake(pipe1.size.width + bird.size.width / 2, CGRectGetMidY(self.frame))
        
        contactNode.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(pipe1.size.width, self.frame.size.height))
        
        contactNode.physicsBody.dynamic = false
        contactNode.physicsBody.categoryBitMask = scoreCategory
        contactNode.physicsBody.contactTestBitMask = birdCategory
        
        pipePair.addChild(contactNode)
        
        pipePair.runAction(movePipesAndRemove)
        pipes.addChild(pipePair)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if moving.speed > 0 {
            bird.physicsBody.velocity = CGVectorMake(0, 0)
            bird.physicsBody.applyImpulse(CGVectorMake(0, 8))
        } else if canRestart {
            self.resetScene()
        }
    }
    
    func clamp(min: CGFloat, max:CGFloat, value:CGFloat) -> CGFloat {
        if value > max { return max }
        if value < min { return min }
        return value
    }
   
    override func update(currentTime: CFTimeInterval) {
        if moving.speed <= 0 {
            return
        }
        
        bird.zRotation = self.clamp(-1, max: 0.5, value: bird.physicsBody.velocity.dy * (bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001))
    }
    
    func didBeginContact(contact: SKPhysicsContact!) {
        if moving.speed <= 0 {
            return
        }
        
        if contact.bodyA.categoryBitMask & scoreCategory == scoreCategory || contact.bodyB.categoryBitMask & scoreCategory == scoreCategory
        {
            score++
            scoreLabelNode.text = "\(score)"
            return
        }
        
        moving.speed = 0
        
        bird.physicsBody.collisionBitMask = worldCategory
        
        var rotateBird = SKAction.rotateByAngle(0.01, duration: 0.003)
        var stopBird = SKAction.runBlock({ () in self.killBirdSpeed() })
        var birdSequence = SKAction.sequence([rotateBird, stopBird])
        bird.runAction(birdSequence)
        
        self.removeActionForKey("flash")
        var turnBackgroundRed = SKAction.runBlock({() in self.setBackgroundRed()})
        
        var wait = SKAction.waitForDuration(0.05)
        var turnBackgroundWhite = SKAction.runBlock({() in self.setBackgroundWhite()})
        
        var turnBackgroundSky = SKAction.runBlock({() in self.setupSky()})
        
        var sequence = SKAction.sequence([turnBackgroundRed, wait, turnBackgroundWhite, wait, turnBackgroundSky])
        var canRestartAction = SKAction.runBlock({() in self.letItRestart()})
        var groupOfActions = SKAction.group([sequence, canRestartAction])
        
        self.runAction(groupOfActions, withKey: "flash")
    }
    
    func killBirdSpeed() {
        bird.speed = 0
    }
    
    func letItRestart() {
        canRestart = true
    }
    
    func setBackgroundRed() {
        self.backgroundColor = UIColor.redColor()
    }
    
    func setBackgroundWhite() {
        self.backgroundColor = UIColor.whiteColor()
    }
    
    func resetScene() {
        score = 0
        scoreLabelNode.text = "\(score)"
        bird.position = CGPoint(x: self.frame.size.width / 2.8, y: CGRectGetMidY(self.frame))
        bird.physicsBody.velocity = CGVectorMake(0, 0)
        bird.physicsBody.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        pipes.removeAllChildren()
        
        canRestart = false
        
        moving.speed = 1
    }
    
    func setupScore() {
        score = 0
        scoreLabelNode.fontName = "Helvetica-Bold"
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.height / 6)
        scoreLabelNode.fontSize = 600
        scoreLabelNode.alpha = 0.2
        scoreLabelNode.zPosition = -30
        scoreLabelNode.text = "\(score)"
        self.addChild(scoreLabelNode)
    }
}
