--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.PUBall = Ball (math.random (5))
    self.PUBall1 = Ball (math.random(5))
    self.level = params.level

    self.PowerUp = PowerUp (self.paddle)
    self.Key = Key (self.paddle)

    self.recoverPoints = params.recoverPoints
    self.timer = 0
    self.keytimer = 0

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    self.NoBalls = 1
    self.PUBall1Flag = false
    self.PUBallFlag = false 
    self.BallFlag = true
    
    self.PowerUpFlag = false
    self.KeyFlag = false
    
    self.KeyPick = params.KeyPick
    self.KeyUsed = params.KeyUsed
end

function PlayState:update(dt)
---------------------------------------------------------
if self.PowerUpFlag == false and self.NoBalls == 1 then
    
    local max = 20 + math.random (0,2000)
    self.timer = self.timer + dt

    if self.timer>=max then
    self.PowerUpFlag = true
    self.PowerUp.dy = 100
    self.PowerUp.x = math.random (VIRTUAL_WIDTH-18)
    self.PowerUp.y = -50
    end
end 

if self.KeyFlag == false and self.KeyPick == false and LMKeyFlag == true then
    local max = 30 + math.random (0,2000)
    self.keytimer = self.keytimer + dt

    if self.keytimer>=max then
    self.KeyFlag = true
    self.Key.dy = 100
    self.Key.x = math.random (VIRTUAL_WIDTH-18)
    self.Key.y = -50
    end

end
---------------------------------------------------------
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

---------------------------------------------------------
if self.PowerUpFlag == true then

    self.PowerUp:update(dt)

   if self.PowerUp:PaddleCollide (self.paddle) == true or love.keyboard.wasPressed ('p') then
       if self.PUBallFlag == false then
          self.PowerUpFlag = false
          self.PUBallFlag = true
          self.PUBall.dx = math.random(-200, 200)
          self.PUBall.dy = math.random(-50, -60)
          self.NoBalls = self.NoBalls + 1
          self.PUBall.x = self.paddle.x + (self.paddle.width / 2) 
          self.PUBall.y = self.paddle.y - 8
        end
        if self.BallFlag == false then
          self.PowerUpFlag = false
          self.BallFlag = true
          self.ball.dx = math.random(-200, 200)
          self.ball.dy = math.random(-50, -60)
          self.NoBalls = self.NoBalls + 1
          self.ball.x = self.paddle.x + (self.paddle.width / 2) 
          self.ball.y = self.paddle.y - 8
        end
        if self.PUBall1Flag == false then
          self.PowerUpFlag = false
          self.PUBall1Flag = true
          self.PUBall1.dx = math.random(-200, 200)
          self.PUBall1.dy = math.random(-50, -60)
          self.NoBalls = self.NoBalls + 1
          self.PUBall1.x = self.paddle.x + (self.paddle.width / 2) 
          self.PUBall1.y = self.paddle.y - 8
        end
    elseif self.PowerUp.y > VIRTUAL_HEIGHT then
    self.PowerUpFlag = false
    self.timer = 0
   end
end

if self.KeyFlag == true then
    self.Key:update (dt)
    if self.Key:PaddleCollide(self.paddle)==true then
        self.KeyFlag=false
        self.KeyPick = true
    elseif self.Key.y>VIRTUAL_HEIGHT then
        self.KeyFlag = false
        self.keytimer = 0
    end
end
---------------------------------------------------------

if self.PUBallFlag==true then

    self.PUBall:update (dt)

    if self.PUBall:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.PUBall.y = self.paddle.y - 8
        self.PUBall.dy = -self.PUBall.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.PUBall.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.PUBall.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.PUBall.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.PUBall.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.PUBall.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.PUBall.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and self.PUBall:collides(brick) then

            if brick.color == 6 and brick.tier == 3 then
                if self.KeyPick == true then
                 self.score = self.score + (brick.tier * 200 + brick.color * 25)
                 self.KeyUsed = true
                 brick:hit()
             end
             else
              -- add to score
              self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
              brick:hit()

            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)
                if self.paddle.size < 4 then 
                    self.paddle.size = self.paddle.size + 1
                end
                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()
                if self.paddle.size < 4 then

                self.paddle.size = self.paddle.size + 1
end
                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.PUBall.x + 2 < brick.x and self.PUBall.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.PUBall.dx = -self.PUBall.dx
                self.PUBall.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.PUBall.x + 6 > brick.x + brick.width and self.PUBall.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.PUBall.dx = -self.PUBall.dx
                self.PUBall.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.PUBall.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.PUBall.dy = -self.PUBall.dy
                self.PUBall.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.PUBall.dy = -self.PUBall.dy
                self.PUBall.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.PUBall.dy) < 150 then
                self.PUBall.dy = self.PUBall.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

if self.PUBall1Flag==true then

    self.PUBall1:update (dt)

    if self.PUBall1:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.PUBall1.y = self.paddle.y - 8
        self.PUBall1.dy = -self.PUBall1.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.PUBall1.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.PUBall1.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.PUBall1.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.PUBall1.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.PUBall1.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.PUBall1.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and self.PUBall1:collides(brick) then

            if brick.color == 6 and brick.tier == 3 then
                if self.KeyPick == true then
                 self.score = self.score + (brick.tier * 200 + brick.color * 25)
                 self.KeyUsed = true
                 brick:hit()
             end
             else
              -- add to score
              self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
              brick:hit()

            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)
                if self.paddle.size < 4 then 
                    self.paddle.size = self.paddle.size + 1
                end
                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()
                if self.paddle.size < 4 then

                self.paddle.size = self.paddle.size + 1
end
                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.PUBall1.x + 2 < brick.x and self.PUBall1.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.PUBall1.dx = -self.PUBall1.dx
                self.PUBall1.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.PUBall1.x + 6 > brick.x + brick.width and self.PUBall1.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.PUBall1.dx = -self.PUBall1.dx
                self.PUBall1.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.PUBall1.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.PUBall1.dy = -self.PUBall1.dy
                self.PUBall1.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.PUBall1.dy = -self.PUBall1.dy
                self.PUBall1.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.PUBall.dy) < 150 then
                self.PUBall1.dy = self.PUBall1.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

    if self.ball:collides(self.paddle) then
        -- raise ball above paddle in case it goes below it, then reverse dy
        self.ball.y = self.paddle.y - 8
        self.ball.dy = -self.ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if self.ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        if brick.inPlay and self.ball:collides(brick) then
            if brick.color == 6 and brick.tier == 3 then
                if self.KeyPick == true then
                 self.score = self.score + (brick.tier * 200 + brick.color * 25)
                 self.KeyUsed = true

                 brick:hit()
             else
                gSounds ['wall-hit']: play ()
             end
             else
              -- add to score
              self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
              brick:hit()

            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                if self.paddle.size < 4 then 
                    self.paddle.size = self.paddle.size + 1
                end

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                if self.paddle.size < 4 then

                self.paddle.size = self.paddle.size + 1
end
                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints

                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball.x + 2 < brick.x and self.ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball.x + 6 > brick.x + brick.width and self.ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball.dx = -self.ball.dx
                self.ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball.dy = -self.ball.dy
                self.ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end



    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        if self.NoBalls > 1 then
            self.NoBalls = self.NoBalls - 1
            self.ball.x = VIRTUAL_WIDTH-12
            self.ball.y = 1
            self.ball.dy = 0
            self.ball.dx = 0
            self.BallFlag = false
            self.timer = 0
            gSounds['hurt']:play()
            return
        else    
        self.health = self.health - 1
if self.paddle.size > 1 then
        self.paddle.size = self.paddle.size - 1
                end
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                KeyPick = self.KeyPick,
                KeyUsed = self.KeyUsed
            })
        end
    end
end

if self.PUBallFlag==true then   

    if self.PUBall.y >= VIRTUAL_HEIGHT then
        if self.NoBalls >1  then
           self.NoBalls = self.NoBalls - 1
           self.PUBall.x = VIRTUAL_WIDTH-12
           self.PUBall.y = 1
           self.PUBall.dy = 0
           self.PUBall.dx = 0
           self.PUBallFlag = false
           self.timer = 0
           gSounds['hurt']:play()
           return
        else 
        self.health = self.health - 1
        gSounds['hurt']:play()
        if self.paddle.size > 1 then
        self.paddle.size = self.paddle.size - 1
        end
        self.PUBallFlag = false

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                KeyPick = self.KeyPick,
                KeyUsed = self.KeyUsed

            })
        end
    end
end
end
if self.PUBall1Flag==true then   

    if self.PUBall1.y >= VIRTUAL_HEIGHT then
        if self.NoBalls > 1 then
           self.NoBalls = self.NoBalls - 1
           self.PUBall1.x = VIRTUAL_WIDTH-12
           self.PUBall1.y = 1
           self.PUBall1.dy = 0
           self.PUBall1.dx = 0
           self.PUBall1Flag = false
           self.timer = 0
           gSounds['hurt']:play()
           return
        else 
        self.health = self.health - 1
        gSounds['hurt']:play()
        if self.paddle.size > 1 then
            self.paddle.size = self.paddle.size - 1
        end
        self.PUBall1Flag = false

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints,
                KeyPick = self.KeyPick,
                KeyUsed = self.KeyUsed

            })
        end
    end
end
end


    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end


function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    if self.PowerUpFlag == true then
        self.PowerUp:render ()
    end

    if self.KeyFlag == true then
        self.Key:render ()
    end

    self.paddle:render()

if self.BallFlag == true then
    self.ball:render()
end

if self.PUBallFlag==true then
    self.PUBall:render()
end
if self.PUBall1Flag==true then
    self.PUBall1:render()
end
    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end

    if self.KeyPick == true and self.KeyUsed == false then 
        love.graphics.draw (gTextures ['main'], gFrames ['key'], 18, VIRTUAL_HEIGHT-20)
    end
    if self.NoBalls > 1 then 
        love.graphics.draw (gTextures ['main'], gFrames ['powerup'], 1, VIRTUAL_HEIGHT-20)
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end