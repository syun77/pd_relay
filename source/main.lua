import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/ui"

import "app/Game"
local game <const> = Game()

function playdate.update()
    game:update()
    game:draw()
end

math.randomseed(playdate.getSecondsSinceEpoch())
