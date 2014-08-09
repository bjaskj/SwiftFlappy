//
//  GameScene.swift
//  SwiftFlappy
//
//  Created by Bjarte Skjørestad on 09/08/14.
//  Copyright (c) 2014 Bjarte Skjørestad. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var bird = SKSpriteNode()
    var skyColor = SKColor()
    var groundTextureHeight = CGFloat()
    var verticalPipeGap = 130.0
    var pipeTexture1 = SKTexture()
    var pipeTexture2 = SKTexture()
    var movePipesAndRemove = SKAction()
    
    override func didMoveToView(view: SKView) {
        setupGravity()
        setupSky()
        setupBird()
        setupGround()
        setupSkyline()
        setupPipes()
    }
    
    func setupGravity() {
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0)
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
        
        self.addChild(bird)
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
            self.addChild(sprite)
        }
        
        var dummyGround = SKNode()
        dummyGround.position = CGPointMake(0, groundTexture.size().height / 2)
        dummyGround.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height))
        dummyGround.physicsBody.dynamic = false
        self.addChild(dummyGround)
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
            self.addChild(sprite)
        }
    }
    
    func setupPipes() {
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
        pipePair.addChild(pipe1)
        
        var pipe2 = SKSpriteNode(texture: pipeTexture2)
        pipe2.position = CGPointMake(0.0, CGFloat(y) + pipe1.size.height + CGFloat(verticalPipeGap))
        pipe2.physicsBody = SKPhysicsBody(rectangleOfSize: pipe2.size)
        pipe2.physicsBody.dynamic = false
        pipePair.addChild(pipe2)
        
        pipePair.runAction(movePipesAndRemove)
        self.addChild(pipePair)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        bird.physicsBody.velocity = CGVectorMake(0, 0)
        bird.physicsBody.applyImpulse(CGVectorMake(0, 8))
    }
    
    func clamp(min: CGFloat, max:CGFloat, value:CGFloat) -> CGFloat {
        if value > max { return max }
        if value < min { return min }
        return value
    }
   
    override func update(currentTime: CFTimeInterval) {
        bird.zRotation = self.clamp(-1, max: 0.5, value: bird.physicsBody.velocity.dy * (bird.physicsBody.velocity.dy < 0 ? 0.003 : 0.001))
    }
}
