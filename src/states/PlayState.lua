--[[
    GD50
    Match-3 Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255/255


    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    self.nopossiblematches = 0
    self.hint = false
    self.pintura = 1
    self.initialitioncheckboard = true
    self.roftoremove = math.random (2)

    self.realmouseX = 0
    self.realmouseY = 0
    self.mouseX = 0
    self.mouseY = 0

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    
    -- grab level # from the params we're passed
    self.level = params.level
    self.NoHints = params.NoHints
    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16, self.level)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000

end

function PlayState:update(dt)

    self.realmouseX, self.realmouseY = love.mouse.getPosition ()

    self.mouseX, self.mouseY = push:toGame (self.realmouseX, self.realmouseY)

    self.mouseX = self.mouseX - 272
    self.mouseY = self.mouseY - 16

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
    -- go back to start if time runs out
    if self.timer <= 0 then
        
        -- clear timers from prior PlayStates
        Timer.clear()
        
        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score,
            NoHints = self.NoHints
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        for y=1, 8 do
            for x=1, 8 do
                --while self.mouseX > VIRTUAL_WIDTH - 272 and self.mouseY > 16 do
                if self.mouseX >= self.board.tiles[y][x].x - 32 and self.mouseX <= self.board.tiles[y][x].x then
                    if self.mouseY >= self.board.tiles[y][x].y and self.mouseY <= self.board.tiles[y][x].y + 32 then
                       self.boardHighlightY = self.board.tiles[y][x].gridY - 1
                       self.boardHighlightX = self.board.tiles[y][x].gridX - 1
                    end
                end
                --end
            end
        end
        if love.keyboard.wasPressed ('h') then
            if self.hint == false and self.NoHints > 0 then
            self.hint = true
            self.NoHints = self.NoHints - 1
            end
        end
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end
        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') or love.mouse.wasPressed(1) then
            
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            
            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
                
                -- swap grid positions of tiles
                self.initialitioncheckboard = false
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY

                local newTile = self.board.tiles[y][x]

                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY

                -- swap tiles in the tiles table
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                    self.highlightedTile

                self.board.tiles[newTile.gridY][newTile.gridX] = newTile

                -- tween coordinates between the two so they swap
                Timer.tween(0.1, {
                    [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                    [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                })
                
                -- once the swap is finished, we can tween falling blocks as needed
                :finish(function()
                    local match = self.board:calculateMatches()
                    if match then
                    self:calculateMatches()
                    self.hint = false
                    self.initialitioncheckboard = true
                    else
                        gSounds['error']:play()
                        newTile.gridX = self.highlightedTile.gridX
                        newTile.gridY = self.highlightedTile.gridY
                        self.highlightedTile.gridY = tempY
                        self.highlightedTile.gridX = tempX

                        self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                        self.highlightedTile
                        self.board.tiles[newTile.gridY][newTile.gridX] = newTile
                       
                        Timer.tween(0.1, {
                            [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                            [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                        }):finish(function()

                        self.highlightedTile = nil
                        end)
                        self.initialitioncheckboard = true
                    end
                end)
            end
        end
    end
    if self.initialitioncheckboard then
  self.checkBoardReturned = self.board:checkBoard(0)
end
    if self.checkBoardReturned [1]>1 then
    self.nopossiblematches = self.checkBoardReturned [1]
    self.ColorHint = self.checkBoardReturned [2][self.pintura]
    else 
    self:nomatches ()
    end


    Timer.update(dt)
end
function love.mousepressed(mouseX,mouseY, button)
    love.mouse.mousePressed[button] = true
end

function love.mouse.wasPressed(button)
    if love.mouse.mousePressed[button] then
        return true
    else
        return false
    end
end

function PlayState:calculateMatches()
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match
        for k, match in pairs(matches) do
            for k, tile in pairs(match) do
                local plus = self.board.tiles[tile.gridY][tile.gridX].variety
                self.score = self.score + plus * 50
                self.timer = self.timer + 1 
            end
        end
       
    self:FallingTiles ()
    -- if no matches, we can continue playing
    else
        self.canInput = true
    end

end

function PlayState:FallingTiles ()
     -- remove any tiles that matched from the board, making empty spaces
        if self.board:removeMatches(false) then
            self.score = self.score + 1000
        end
        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()
        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
       -- if self.board:checkBoard (1) == false then
       --end
            self:calculateMatches()
        end)
end

function PlayState:nomatches ()

    local specialmatches = {}
    local match = {}

   if self.roftoremove == 1 then
    for x=1, 4 do
        for y=1, 8 do
            table.insert(match, self.board.tiles[y][x*2])
        end
    end
 elseif self.roftoremove == 2 then
    local x = 1
    while x<8 do
        for y=1, 8 do
            table.insert(match, self.board.tiles[y][x])
        end
        x = x+2
    end 
 end


    table.insert (specialmatches, match)

    self.board:removeMatches (specialmatches)

    local tilesToFall = self.board:getFallingTiles()
        Timer.tween(0.25, tilesToFall):finish(function()
        self:calculateMatches()
    end)

end

function PlayState:render()
    -- render board of tiles
    self.board:render()
    -- render highlighted tile if it exists
    if self.highlightedTile then
        
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255/255, 255/255, 255/255, 96/255)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217/255, 87/255, 99/255, 255/255)
    else
        love.graphics.setColor(172/255, 50/255, 50/255, 255/255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56/255, 56/255, 56/255, 234/255)
    love.graphics.rectangle('fill', 16, 16, 186, 186, 4)

    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('posiblematches: ' .. tostring(self.nopossiblematches), 20, 140, 182, 'center')

    love.graphics.setColor(99/255, 155/255, 255/255, 255/255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')

    if self.hint == true then
        love.graphics.setColor(255/255, 255/255, 255/255, 255/255)
        love.graphics.draw(gTextures['main'], gFrames['tiles'][self.ColorHint][1],
        85, 158 )
    else
        love.graphics.setFont(gFonts['medium'])
        love.graphics.printf('Hints left: ' .. tostring(self.NoHints), 20, 165, 182, 'center')
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf('Press h to use a hint', 20, 180, 182, 'center')
    end
end