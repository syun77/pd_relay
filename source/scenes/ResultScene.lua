import "scenes/Scene"
import "domain/Tile"
import "presentation/TileRenderer"

ResultScene = class("ResultScene").extends(Scene) or ResultScene

function ResultScene:init(context)
    ResultScene.super.init(self, context)
end

function ResultScene:update(input, now)
    local match = self.context.match
    if input:released("A") then
        if match.handNumber >= 4 then
            self.context.sceneManager:change(self.context.titleScene())
        else
            match:advanceHand()
            self.context.sceneManager:change(self.context.handScene())
        end
    end
end

function ResultScene:draw()
    local gfx, match = playdate.graphics, self.context.match
    local result = match.lastResult
    gfx.drawText("TSUKIKAGE JANTO", 8, 3)
    gfx.drawText("E" .. match.handNumber .. "  " .. (match.dealer == 1 and "OYA" or "CPU OYA"), 160, 3)
    gfx.drawText("YOU " .. match:score(1), 8, 17)
    gfx.drawText("CPU " .. match:score(2), 108, 17)

    local title = "DRAW HAND"
    if result and result.winner == 1 then title = "PLAYER " .. result.winType
    elseif result and result.winner == 2 then title = "CPU " .. result.winType end
    gfx.drawTextAligned(title, 200, 42, kTextAlignment.center)

    if result and result.info then
        gfx.drawText("YAKU", 20, 72)
        gfx.drawTextAligned(result.info.names, 225, 72, kTextAlignment.center)
        gfx.drawText("WIN", 20, 98)
        self:drawTile(result.winTile, 58, 92, 23, 28)
        gfx.drawText("+" .. result.points, 94, 101)
    else
        gfx.drawTextAligned("No points move.", 200, 92, kTextAlignment.center)
    end

    if result and result.cpuHand and match.handNumber < 4 then
        gfx.drawText("CPU HAND", 20, 136)
        for i, tile in ipairs(result.cpuHand) do self:drawTile(tile, 20 + (i - 1) * 26, 154, 22, 27) end
    end
    gfx.drawText("YOU " .. match:score(1) .. "     CPU " .. match:score(2), 93, 198)
    if match.handNumber >= 4 then
        local winner = match:score(1) == match:score(2) and "SUDDEN DEATH"
            or (match:score(1) > match:score(2) and "YOU WIN MATCH" or "CPU WINS MATCH")
        gfx.drawTextAligned(winner, 200, 180, kTextAlignment.center)
        gfx.drawText("A TITLE", 8, 223)
    else
        gfx.drawText("A NEXT HAND", 8, 223)
    end
end

function ResultScene:drawTile(tile, x, y, w, h)
    TileRenderer.draw(tile, x, y, w, h, true, false)
end

return ResultScene
