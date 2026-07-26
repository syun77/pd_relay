import "Constants"
import "scenes/Scene"
import "domain/Tile"
import "presentation/TileRenderer"

local gfx <const> = playdate.graphics

---@class ResultScene: Scene 結果シーン.
---@field super Scene 親クラス.
ResultScene = class("ResultScene").extends(Scene) or ResultScene

---初期化.
function ResultScene:init(context)
    ResultScene.super.init(self, context)
end

---更新.
---@param input InputManager 入力管理.
---@param now number 現在の時間.
function ResultScene:update(input, now)
    local match = self.context.match
    if input:released("A") then
        if match.handNumber >= Constants.Game.HANDS_PER_MATCH then
            self.context.sceneManager:change(self.context:titleScene())
        else
            match:advanceHand()
            self.context.sceneManager:change(self.context:handScene())
        end
    end
end

---描画.
function ResultScene:draw()
    local match = self.context.match
    local result = match.lastResult
    gfx.drawText("TSUKIKAGE JANTO", 8, 3)
    gfx.drawText("E" .. match.handNumber .. "  " .. (match.dealer == Constants.Game.PLAYER_ID.HUMAN and "OYA" or "CPU OYA"), 160, 3)
    gfx.drawText("YOU " .. match:score(Constants.Game.PLAYER_ID.HUMAN), 8, 17)
    gfx.drawText("CPU " .. match:score(Constants.Game.PLAYER_ID.CPU), 108, 17)

    local title = "DRAW HAND"
    if result and result.winner == Constants.Game.PLAYER_ID.HUMAN then title = "PLAYER " .. result.winType
    elseif result and result.winner == Constants.Game.PLAYER_ID.CPU then title = "CPU " .. result.winType end
    gfx.drawTextAligned(title, Constants.UI.SCREEN.CENTER_X, 42, kTextAlignment.center)

    if result and result.info then
        gfx.drawText("YAKU", 20, 72)
        gfx.drawTextAligned(result.info.names, 225, 72, kTextAlignment.center)
        gfx.drawText("WIN", 20, 98)
        self:drawTile(result.winTile, 58, 92, 23, 28)
        gfx.drawText("+" .. result.points, 94, 101)
    else
        gfx.drawTextAligned("No points move.", Constants.UI.SCREEN.CENTER_X, 92, kTextAlignment.center)
    end

    if result and result.cpuHand and match.handNumber < Constants.Game.HANDS_PER_MATCH then
        gfx.drawText("CPU HAND", 20, 136)
        for i, tile in ipairs(result.cpuHand) do self:drawTile(tile, 20 + (i - 1) * 26, 154, 22, 27) end
    end
    gfx.drawText(
        "YOU " .. match:score(Constants.Game.PLAYER_ID.HUMAN)
            .. "     CPU " .. match:score(Constants.Game.PLAYER_ID.CPU),
        93,
        198
    )
    if match.handNumber >= Constants.Game.HANDS_PER_MATCH then
        local playerScore = match:score(Constants.Game.PLAYER_ID.HUMAN)
        local cpuScore = match:score(Constants.Game.PLAYER_ID.CPU)
        local winner = playerScore == cpuScore and "SUDDEN DEATH"
            or (playerScore > cpuScore and "YOU WIN MATCH" or "CPU WINS MATCH")
        gfx.drawTextAligned(winner, Constants.UI.SCREEN.CENTER_X, 180, kTextAlignment.center)
        gfx.drawText("A TITLE", 8, 223)
    else
        gfx.drawText("A NEXT HAND", 8, 223)
    end
end

---牌の描画.
---@param tile number 牌の種類.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
function ResultScene:drawTile(tile, x, y, w, h)
    TileRenderer.draw(tile, x, y, w, h, true, false)
end

return ResultScene
