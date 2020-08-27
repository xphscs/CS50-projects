IA = Class{}


function IA:update (dt)

	if ball.dx < 0 then 
		if gameMode == 'cvc' then
			if gameDif == 'hard' then
				player1IA ()
			elseif gameDif == 'easy' then
				if ball.x < VIRTUAL_WIDTH/4 then
					player1IA ()
				end
			end
		end

	elseif ball.dx > 0 then
		if gameMode == 'pvc' or gameMode == 'cvc' then
			if gameDif == 'hard' then
				player2IA ()
			elseif gameDif == 'easy' then
				if ball.x > VIRTUAL_WIDTH*3/4 then
					player2IA ()
				end
			end
		end
	end
end

function player1IA ()

	if ball.y == player1.y + player1.height/2 then
		player1.dy = 0
	elseif ball.y < player1.y + player1.height/2 then
		player1.dy = -PADDLE_SPEED
	elseif ball.y > player1.y then
		player1.dy = PADDLE_SPEED
	end
 
end

function player2IA ()

	if ball.y == player2.y + player2.height/2 then
		player2.dy = 0
	elseif ball.y < player2.y  then
		player2.dy = -PADDLE_SPEED
	elseif ball.y > player2.y  then
		player2.dy = PADDLE_SPEED
	end
 
end
