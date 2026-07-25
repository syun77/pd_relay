import "scenes/Scene"
import "domain/Tile"
import "domain/MahjongRules"
import "domain/ScoreCalculator"
import "presentation/TileRenderer"

class("HandScene").extends(Scene)

function HandScene:init(context)
    HandScene.super.init(self, context)
    self.selected = 1
    self.state = "PLAYER"
    self.deadline = 0
    self.toast = ""
    self.toastUntil = 0
end

function HandScene:enter()
    self.state = "PLAYER"
    self.selected = 1
    self.deadline = 0
    self.pendingTile = nil
    local tile, info = self.context.match:drawForPlayer()
    if not tile then self:showResult(info); return end
    if info then self.state = "TSUMO" end
end

function HandScene:showResult(result)
    local match = self.context.match
    match:finishHand(result.winner, result.winType, nil, nil)
    self.context.sceneManager:change(self.context.resultScene())
end

function HandScene:update(input, now)
    local match = self.context.match
    local player = match:player()

    if input:released("MENU") then self.context.sceneManager:change(self.context.helpScene()); return end
    if self.state == "PLAYER" then
        if input:pressed("LEFT") then self.selected = self.selected - 1 end
        if input:pressed("RIGHT") then self.selected = self.selected + 1 end
        self.selected = math.max(1, math.min(#player.hand.tiles, self.selected))
        if input:released("A") then
            local discard, event = match:playerDiscard(self.selected, input:event("A").long)
            if not discard then self:showToast(event, now + 1100)
            elseif event.type == "CPU_RON" then
                match:finishHand(2, "RON", event.tile, event.info)
                self.context.sceneManager:change(self.context.resultScene())
            else
                self.state = "CPU"
                self.deadline = now + 350
            end
        elseif input:released("B") and input:event("B").long then
            self.state = "ABILITY"
        end
    elseif self.state == "ABILITY" then
        if input:released("A") then
            local ok, message = match:useReverse()
            if ok then self:enter() else self:showToast(message, now + 1200); self.state = "PLAYER" end
        elseif input:released("B") then self.state = "PLAYER" end
    elseif self.state == "TSUMO" then
        if input:released("A") then
            local info = ScoreCalculator.calculate(player.hand.tiles, player.hand.riichi, match.wall.doraIndicator)
            match:finishHand(1, "TSUMO", player.hand.tiles[#player.hand.tiles], info)
            self.context.sceneManager:change(self.context.resultScene())
        elseif input:released("B") then self.state = "PLAYER" end
    elseif self.state == "RON" then
        if input:released("A") then
            local info = ScoreCalculator.calculate(Rules.appendTile(player.hand.tiles, self.pendingTile), player.hand.riichi, match.wall.doraIndicator)
            match:finishHand(1, "RON", self.pendingTile, info)
            self.context.sceneManager:change(self.context.resultScene())
        elseif input:released("B") then self.state = "PLAYER"; self:drawNext(now) end
    elseif self.state == "CPU" and now >= self.deadline and not input:pressed("B") then
        local event = match:cpuTurn()
        if event.type == "CPU_TSUMO" then
            match:finishHand(2, "TSUMO", event.tile, event.info)
            self.context.sceneManager:change(self.context.resultScene())
        elseif event.type == "RON" then
            self.pendingTile = event.tile
            self.state = "RON"
        else
            self:drawNext(now)
        end
    end
end

function HandScene:drawNext(now)
    local tile, info = self.context.match:drawForPlayer()
    if not tile then self:showResult(info); return end
    self.state = info and "TSUMO" or "PLAYER"
    if self.state == "PLAYER" and self.context.match:player().hand.riichi then
        self.selected = #self.context.match:player().hand.tiles
        self.deadline = now + 500
    end
end

function HandScene:showToast(message, untilTime)
    self.toast, self.toastUntil = message or "", untilTime
end

function HandScene:draw()
    local gfx, match = playdate.graphics, self.context.match
    local player, cpu = match:player(), match:cpu()
    gfx.drawText("TSUKIKAGE JANTO", 8, 3)
    gfx.drawText("E" .. match.handNumber .. "  " .. (match.dealer == 1 and "OYA" or "CPU OYA"), 160, 3)
    gfx.drawText("YOU " .. match:score(1), 8, 17); gfx.drawText("CPU " .. match:score(2), 108, 17)
    gfx.drawText("D:" .. Tile.text(match.wall.doraIndicator or 0), 306, 3)
    gfx.drawText("CPU", 8, 34)
    for i = 1, 13 do self:drawBack(48 + (i - 1) * 25, 31, 20, 25) end
    gfx.drawText("CPU RIVER", 8, 59); self:drawRiver(cpu.hand.river, 75)
    gfx.drawLine(0, 113, 399, 113)
    local center = self.state == "PLAYER" and "CHOOSE A TILE" or self.state == "TSUMO" and "TSUMO?  A: YES   B: NO" or self.state == "RON" and "RON?  A: YES   B: NO" or self.state == "CPU" and "CPU THINKING..." or "ABILITY: A REVERSE  B CLOSE"
    gfx.drawTextAligned(center, 200, 115, kTextAlignment.center)
    gfx.drawText("YOU RIVER", 8, 135); self:drawRiver(player.hand.river, 150)
    for i, tile in ipairs(player.hand.tiles) do self:drawTile(tile, 7 + (i - 1) * 28, 188, 25, 30, i == self.selected and self.state == "PLAYER") end
    gfx.drawText(self.state == "PLAYER" and "A CUT   A-HOLD RIICHI   B-HOLD ABILITY" or "A NEXT   B-HOLD REVERSE", 8, 224)
    if self.toast ~= "" and playdate.getCurrentTimeMilliseconds() < self.toastUntil then
        gfx.fillRect(48, 100, 304, 32); gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(self.toast, 200, 111, kTextAlignment.center); gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
end

function HandScene:drawTile(tile, x, y, w, h, selected)
    TileRenderer.draw(tile, x, y, w, h, w <= 25, selected)
end

function HandScene:drawBack(x, y, w, h)
    TileRenderer.drawBack(x, y, w, h)
end

function HandScene:drawRiver(river, y)
    for i = 1, math.min(#river, 18) do
        self:drawTile(river[i], 8 + ((i - 1) % 9) * 29, y + math.floor((i - 1) / 9) * 22, 25, 18, false)
    end
end

return HandScene
