Medals = Class {}

function Medals:init (_score)

	self.image5 = love.graphics.newImage ('5medal.png')
	self.image5_y = (VIRTUAL_HEIGHT/6)*1
	self.image10 = love.graphics.newImage ('10medal.png')
	self.image10_y = (VIRTUAL_HEIGHT/6)*2
	self.image25 = love.graphics.newImage ('25medal.png')
	self.image25_y = (VIRTUAL_HEIGHT/6)*3
	self.image50 = love.graphics.newImage ('50medal.png')
	self.image50_y = (VIRTUAL_HEIGHT/6)*4

	self.score =0

	self.x = 30

end

function Medals:update (_score)

	self.score = _score

end

function Medals:render ()
--Messages when giving a medal 

if self.score == 5 then 
    love.graphics.setFont(smallFont)
    love.graphics.printf('You have archieved a bronze medal!', 0, 40, VIRTUAL_WIDTH, 'center')
 end
 if self.score == 10 then 
    love.graphics.setFont(smallFont)
    love.graphics.printf('You have archieved a silver medal!', 0, 40, VIRTUAL_WIDTH, 'center')
 end
 if self.score == 25 then 
    love.graphics.setFont(smallFont)
    love.graphics.printf('You have archieved a gold medal!', 0, 40, VIRTUAL_WIDTH, 'center')
 end
 if self.score == 50 then 
    love.graphics.setFont(smallFont)
    love.graphics.printf('YOU HAVE GOT THE CS50 MEDAL', 0, 40, VIRTUAL_WIDTH, 'center')
 end



-- medal

	if self.score >= 5 then
		love.graphics.draw (self.image5, self.x, self.image5_y )
end
	if self.score >= 10 then
		love.graphics.draw (self.image10, self.x, self.image10_y )
end
	if self.score >= 25 then
		love.graphics.draw (self.image25, self.x, self.image25_y )
end
	if self.score >= 50 then
		love.graphics.draw (self.image50, self.x, self.image50_y )
end

end