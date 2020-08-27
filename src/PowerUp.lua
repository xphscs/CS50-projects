PowerUp = Class {}

function PowerUp:init (paddle)
self.y = 0
self.x = 0
self.dy = 0

self.width = 16
self.height = 16

self.paddle = paddle

end

function PowerUp:update (dt)

	self.y = self.y + (self.dy * dt)

end

function PowerUp:PaddleCollide (paddle)
self.paddle = paddle
 if self.y+self.height >= self.paddle.y and self.y<self.paddle.y then
 	if self.x+self.width >= self.paddle.x and self.x <= self.paddle.x + self.paddle.width then
 		gSounds ['victory']:play()
 		self.y = 0
 		self.x = 0
 		self.dy = 0
 		return true
 	else return false
 	end
end
end

function PowerUp:render ()

	love.graphics.draw (gTextures['main'], gFrames ['powerup'], self.x, self.y)

end
