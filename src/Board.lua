--[[
    GD50
    Match-3 Remake

    -- Board Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    The Board is our arrangement of Tiles with which we must try to find matching
    sets of three horizontally or vertically.
]]

Board = Class{}

function Board:init(x, y, level)
    self.x = x
    self.y = y
    self.matches = {}
    self.level = level

    self:initializeTiles()
end

function Board:initializeTiles()
    self.tiles = {}

    for tileY = 1, 8 do
        
        -- empty table that will serve as a new row
        table.insert(self.tiles, {})

        for tileX = 1, 8 do
            
            local specialGreatTileRandomizer = math.random (35)
            local variety = 1

            if specialGreatTileRandomizer == 1 then
               variety = 6
            elseif specialGreatTileRandomizer > 1 and specialGreatTileRandomizer < 10 then
                variety = math.random (5)
            else 
                variety = 1
            end
            -- create a new tile at X,Y with a random color and variety
            if self.level == 1 then
            table.insert(self.tiles[tileY], Tile(tileX, tileY, (math.random(6)*3), 1)) --math.random(6)))
            elseif self.level == 2 then
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(9)*2, 1))
            elseif self.level > 2 and self.level < 5 then
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(9)*2, variety))
            elseif self.level > 4 then
            table.insert(self.tiles[tileY], Tile(tileX, tileY, math.random(18), variety))        
            end

        end
    end

    while self:calculateMatches() do
        
        -- recursively initialize if matches were returned so we always have
        -- a matchless board on start
        self:initializeTiles()
    end
end

--[[
    Goes left to right, top to bottom in the board, calculating matches by counting consecutive
    tiles of the same color. Doesn't need to check the last tile in every row or column if the 
    last two haven't been a match.
]]
function Board:calculateMatches()
    self.matches = nil
    local matches = {nil}

    -- how many of the same color blocks in a row we've found
    local matchNum = 1

    -- horizontal matches first
    for y = 1, 8 do
        local colorToMatch = self.tiles[y][1].color

        matchNum = 1
        
        -- every horizontal tile
        for x = 2, 8 do
            
            -- if this is the same color as the one we're trying to match...
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                
                -- set this as the new color we want to watch for
                colorToMatch = self.tiles[y][x].color

                -- if we have a match of 3 or more up to now, add it to our matches table
                if matchNum >= 3 then
                    local match = {}

                    -- go backwards from here by matchNum
                    for x2 = x - 1, x - matchNum, -1 do
                        
                        -- add each tile to the match that's in that match
                        table.insert(match, self.tiles[y][x2])
                    end

                    -- add this match to our total matches table
                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if x >= 7 then
                    break
                end
            end
        end

        -- account for the last row ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for x = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- vertical matches
    for x = 1, 8 do
        local colorToMatch = self.tiles[1][x].color

        matchNum = 1

        -- every vertical tile
        for y = 2, 8 do
            if self.tiles[y][x].color == colorToMatch then
                matchNum = matchNum + 1
            else
                colorToMatch = self.tiles[y][x].color

                if matchNum >= 3 then
                    local match = {}

                    for y2 = y - 1, y - matchNum, -1 do
                        table.insert(match, self.tiles[y2][x])
                    end

                    table.insert(matches, match)
                end

                matchNum = 1

                -- don't need to check last two if they won't be in a match
                if y >= 7 then
                    break
                end
            end
        end

        -- account for the last column ending with a match
        if matchNum >= 3 then
            local match = {}
            
            -- go backwards from end of last row by matchNum
            for y = 8, 8 - matchNum + 1, -1 do
                table.insert(match, self.tiles[y][x])
            end

            table.insert(matches, match)
        end
    end

    -- store matches for later reference
    self.matches = matches

    -- return matches table if > 0, else just return false
    return #self.matches > 0 and self.matches or false
end


--[[
    Remove the matches from the Board by just setting the Tile slots within
    them to nil, then setting self.matches to nil.
]]
function Board:removeMatches(_specialmatches)
    if _specialmatches then
        self.matches = _specialmatches
    end
    for k, match in pairs(self.matches) do
        local specialremove = false
        local specialx = 0
        local specialy = 0
        for k, tile in pairs(match) do
            if self.tiles[tile.gridY][tile.gridX].variety == 6 then
                specialremove = true
                specialx = self.tiles[tile.gridY][tile.gridX].gridX
                specialy = self.tiles[tile.gridY][tile.gridX].gridY
            elseif self.tiles[tile.gridY][tile.gridX] then
            self.tiles[tile.gridY][tile.gridX] = nil
            end
        end
        if specialremove == true then
            for y = 1, 8 do 
                self.tiles[y][specialx] = nil
            end
            for x = 1, 8 do 
                self.tiles[specialy][x] = nil
            end
            if specialy > 1 then
                if specialx > 1 then
                  self.tiles[specialy - 1][specialx - 1] = nil
                end
                if specialx < 8 then
                  self.tiles[specialy - 1][specialx + 1] = nil
                end
            end
            if specialy < 8 then
                if specialx > 1 then
                  self.tiles[specialy + 1][specialx - 1] = nil
                end
                if specialx < 8 then
                  self.tiles[specialy + 1][specialx + 1] = nil 
                end 
            end          
            gSounds['next-level']:play()

            return true

        end
    end

    return false

end

--[[
    Shifts down all of the tiles that now have spaces below them, then returns a table that
    contains tweening information for these new tiles.
]]
function Board:getFallingTiles()
    -- tween table, with tiles as keys and their x and y as the to values
    local tweens = {}

    -- for each column, go up tile by tile till we hit a space
    for x = 1, 8 do
        local space = false
        local spaceY = 0

        local y = 8
        while y >= 1 do
            
            -- if our last tile was a space...
            local tile = self.tiles[y][x]
            
            if space then
                
                -- if the current tile is *not* a space, bring this down to the lowest space
                if tile then
                    
                    -- put the tile in the correct spot in the board and fix its grid positions
                    self.tiles[spaceY][x] = tile
                    tile.gridY = spaceY

                    -- set its prior position to nil
                    self.tiles[y][x] = nil

                    -- tween the Y position to 32 x its grid position
                    tweens[tile] = {
                        y = (tile.gridY - 1) * 32
                    }

                    -- set Y to spaceY so we start back from here again
                    space = false
                    y = spaceY

                    -- set this back to 0 so we know we don't have an active space
                    spaceY = 0
                end
            elseif tile == nil then
                space = true
                
                -- if we haven't assigned a space yet, set this to it
                if spaceY == 0 then
                    spaceY = y
                end
            end

            y = y - 1
        end
    end

    -- create replacement tiles at the top of the screen
    for x = 1, 8 do
        for y = 8, 1, -1 do
            local tile = self.tiles[y][x]

            -- if the tile is nil, we need to add a new one
            if not tile then

                -- new tile with random color and variety
                if self.level == 1 then
                 local tile = Tile(x, y, (math.random (6) * 3), 1)
                  tile.y = -32
                  self.tiles[y][x] = tile

                 -- create a new tween to return for this tile to fall down
                 tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                 }
                 elseif self.level == 2 then
                 local tile = Tile(x, y, math.random(9)*2, 1)
                  tile.y = -32
                  self.tiles[y][x] = tile

                  -- create a new tween to return for this tile to fall down
                  tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                 }
                 elseif self.level > 2 and self.level < 5 then
                 local tile = Tile(x, y, math.random(9)*2, math.random(5))   
                 tile.y = -32
                 self.tiles[y][x] = tile

                 -- create a new tween to return for this tile to fall down
                 tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                 }
                elseif self.level > 4 then
                    local tile = Tile(x, y, math.random(18), math.random(5))   
                 tile.y = -32
                 self.tiles[y][x] = tile

                 -- create a new tween to return for this tile to fall down
                 tweens[tile] = {
                    y = (tile.gridY - 1) * 32
                 }
                end


            end
        end
    end


    return tweens
end

function Board:checkBoard (_min)
    
    local posiblematches = 0
    local numtiles = 1
    local matchcolor = {}

    local min = _min

    for y = 1, 8 do

        local pcolor = self.tiles[y][1].color
        numtiles = 1

        for x=2,8 do
             --------------------------------------------------
            if self.tiles[y][x].color == pcolor then
                numtiles = 2
            elseif x < 8 then
                if y<8 and self.tiles[y][x+1].color == pcolor and self.tiles[y+1][x].color == pcolor then
                    posiblematches = posiblematches + 1
                    matchcolor[posiblematches] = pcolor
                end
                if y>1 and self.tiles[y][x+1].color== pcolor and self.tiles[y-1][x].color == pcolor then
                    posiblematches = posiblematches + 1
                    matchcolor[posiblematches] = pcolor
                end
            end                
            if numtiles == 2 then
                if y > 1 and y<8 then
                    if x<7 and x>3 then
                         if self.tiles[y][x+2].color == pcolor
                         or self.tiles[y+1][x+1].color == pcolor 
                         or self.tiles[y-1][x+1].color == pcolor 
                         or self.tiles[y][x-3].color == pcolor
                         or self.tiles[y+1][x-2].color == pcolor 
                         or self.tiles[y-1][x-2].color == pcolor then
                           posiblematches = posiblematches + 1
                           matchcolor[posiblematches] = pcolor
                        end
                    elseif x<3 then
                        if self.tiles[y][x+2].color == pcolor 
                         or self.tiles[y+1][x+1].color == pcolor 
                         or self.tiles[y-1][x+1].color == pcolor then
                           posiblematches = posiblematches + 1
                           matchcolor[posiblematches] = pcolor
                        end
                    elseif x>6 then
                        if self.tiles[y][x-3].color == pcolor 
                         or self.tiles[y+1][x-2].color == pcolor 
                         or self.tiles[y-1][x-2].color == pcolor then
                           posiblematches = posiblematches + 1
                           matchcolor[posiblematches] = pcolor
                        end
                          if x==7 then
                                if self.tiles[y+1][x+1].color == pcolor 
                                  or self.tiles[y-1][x+1].color == pcolor then
                                  posiblematches = posiblematches + 1
                                  matchcolor[posiblematches] = pcolor
                                end
                          end
                    end
                else
                    if y==1 then
                        if x<7 and x>3 then
                            if self.tiles[y][x+2].color == pcolor or self.tiles[y+1][x+1].color == pcolor 
                            or self.tiles[y][x-3].color == pcolor or self.tiles[y+1][x-2].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        elseif x<3 then
                            if self.tiles[y][x+2].color == pcolor or self.tiles[y+1][x+1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        elseif x>6 then
                            if self.tiles[y][x-3].color == pcolor or self.tiles[y+1][x-2].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                            if x==7 then
                                if self.tiles[y+1][x+1].color == pcolor then
                                 posiblematches = posiblematches + 1
                                 matchcolor[posiblematches] = pcolor
                                 end
                            end
                        end
                    elseif y==8 then
                        if x<7 and x>3 then
                           if self.tiles[y][x+2].color == pcolor or self.tiles[y-1][x+1].color == pcolor 
                           or self.tiles[y][x-3].color == pcolor or self.tiles[y-1][x-2].color == pcolor then
                            posiblematches = posiblematches + 1
                            matchcolor[posiblematches] = pcolor
                           end
                        elseif x<3 then
                            if self.tiles[y][x+2].color == pcolor or self.tiles[y-1][x+1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        elseif x>6 then
                            if self.tiles[y][x-3].color == pcolor or self.tiles[y-1][x-2].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                            if x==7 then
                                if self.tiles[y-1][x+1].color == pcolor then
                                  posiblematches = posiblematches + 1
                                  matchcolor[posiblematches] = pcolor
                                end
                            end
                        end
                    end
                end
                numtiles = 1  
            end
        pcolor = self.tiles[y][x].color
        end
    end

    for x = 1, 8 do
        pcolor = self.tiles[1][x].color
        numtiles = 1
        for y=2, 8 do
            if self.tiles[y][x].color == pcolor then
                numtiles = 2
            elseif y<8 then
                if x<8 and self.tiles[y+1][x].color == pcolor and self.tiles[y][x+1].color == pcolor then
                    posiblematches = posiblematches + 1
                    matchcolor[posiblematches] = pcolor
                end
                if x>1 and self.tiles[y+1][x].color == pcolor and self.tiles[y][x-1].color == pcolor then
                    posiblematches = posiblematches + 1
                    matchcolor[posiblematches] = pcolor
                end
            end
            if numtiles == 2 then
            if x<8 and x>1 then
                if y<7 and y>3 then
                    if self.tiles[y+2][x].color == pcolor
                      or self.tiles[y+1][x+1].color == pcolor 
                      or self.tiles[y+1][x-1].color == pcolor 
                      or self.tiles[y-3][x].color == pcolor
                      or self.tiles[y-2][x+1].color == pcolor 
                      or self.tiles[y-2][x-1].color == pcolor then
                        posiblematches = posiblematches + 1
                        matchcolor[posiblematches] = pcolor
                      end
                    elseif y<4 then
                        if self.tiles[y+2][x].color == pcolor 
                         or self.tiles[y+1][x+1].color == pcolor 
                         or self.tiles[y+1][x-1].color == pcolor then
                          posiblematches = posiblematches + 1
                          matchcolor[posiblematches] = pcolor
                        end
                    elseif y>6 then
                        if self.tiles[y-3][x].color == pcolor 
                         or self.tiles[y-2][x+1].color == pcolor 
                         or self.tiles[y-2][x-1].color == pcolor then
                         posiblematches = posiblematches + 1
                         matchcolor[posiblematches] = pcolor
                        end
                        if y==7 then
                            if self.tiles[y+1][x+1].color == pcolor 
                             or self.tiles[y+1][x-1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        end
                    end
                else
                    if x==1 then
                        if y<7 and y>3 then
                            if self.tiles[y+2][x].color == pcolor or self.tiles[y+1][x+1].color == pcolor 
                             or self.tiles[y-3][x].color == pcolor or self.tiles[y-2][x+1].color == pcolor then
                              posiblematches = posiblematches + 1
                              matchcolor[posiblematches] = pcolor
                            end
                      elseif y<4 then
                            if self.tiles[y+2][x].color == pcolor or self.tiles[y+1][x+1].color == pcolor then
                                posiblematches = posiblematches + 1
                                matchcolor[posiblematches] = pcolor
                            end
                      elseif y>6 then
                            if self.tiles[y-3][x].color == pcolor or self.tiles[y-2][x+1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                            if y==7 then
                                 if self.tiles[y+1][x+1].color == pcolor then
                                 posiblematches = posiblematches + 1
                                 matchcolor[posiblematches] = pcolor
                                 end
                            end
                      end
                    elseif x==8 then
                        if y<7 and y>3 then
                            if self.tiles[y+2][x].color == pcolor or self.tiles[y+1][x-1].color == pcolor 
                             or self.tiles[y-3][x].color == pcolor or self.tiles[y-2][x-1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        elseif y<4 then
                            if self.tiles[y+2][x].color == pcolor or self.tiles[y+1][x-1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                        elseif y>6 then
                            if self.tiles[y-3][x].color == pcolor or self.tiles[y-2][x-1].color == pcolor then
                             posiblematches = posiblematches + 1
                             matchcolor[posiblematches] = pcolor
                            end
                            if y==7 then
                                if self.tiles[y+1][x-1].color == pcolor then
                                 posiblematches = posiblematches + 1
                                 matchcolor[posiblematches] = pcolor
                                end
                            end
                        end
                    end
                end
             numtiles = 1
            end
         pcolor = self.tiles[y][x].color
        end
    end

 local returningthing = {posiblematches, matchcolor}
 local falsereturn = {1, 1}
    if posiblematches > min then
        return returningthing
    else
        return falsereturn
    end
end

function Board:render()
    for y = 1, #self.tiles do
        for x = 1, #self.tiles[1] do
            self.tiles[y][x]:render(self.x, self.y)
        end
    end
end