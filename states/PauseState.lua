

PauseState = Class{__includes = BaseState}

function PauseState:enter(params)
    self.score = params.score
    self.bird = params.bird
    self.timer = params.timer
    self.pipePairs = params.pipePairs
    self.medal = params.medal
end

scrolling = false


function PauseState:update (dt)
    GROUND_SCROLL_SPEED = 0
    BACKGROUND_SCROLL_SPEED = 0

	if love.keyboard.wasPressed ('p') then
            gStateMachine:change('play', {
            bird = self.bird,
            pipePairs = self.pipePairs,
            timer = self.timer,
            score = self.score,
            medal = self.medal
            })
	end

    sounds['music']:pause()

end

function PauseState:render ()

    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end

    self.bird:render()

	love.graphics.setFont(flappyFont)
    love.graphics.printf('PAUSE', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(smallFont)
    love.graphics.printf('Press P to Continue Playing!', 0, 160, VIRTUAL_WIDTH, 'center')

  end

  function PauseState:exit ()
  end

