--[[
=========================================================
	TitleScene.lua
	タイトルシーン.
=========================================================
]]
import "Constants"
import "scenes/Scene"

local gfx <const> = playdate.graphics

---@class TitleScene: Scene タイトルシーン.
---@field super Scene 親クラス.
---@field selected number 選択項目.
TitleScene = class("TitleScene").extends(Scene) or TitleScene

---初期化.
function TitleScene:init(context)
    TitleScene.super.init(self, context)
    self.selected = Constants.Game.CPU_TYPE.YUI
end

---更新.
---@param input InputManager 入力管理.
---@param now number 現在時刻.
function TitleScene:update(input, now)
	-- CPUの種類を選択.
    if input:pressed("UP") or input:pressed("LEFT") then
        self.selected = math.max(Constants.UI.TITLE.FIRST_ITEM, self.selected - 1)
    elseif input:pressed("DOWN") or input:pressed("RIGHT") then
        self.selected = math.min(Constants.UI.TITLE.LAST_ITEM, self.selected + 1)
    elseif input:released("MENU") then
        self.context.sceneManager:change(self.context:helpScene())
    elseif input:released("A") then
		-- 項目実行.
        if self.selected == Constants.UI.TITLE.LAST_ITEM then
			-- ヘルプシーンに遷移.
            self.context.sceneManager:change(self.context:helpScene())
        else
			-- 対戦開始.
            self.context:startMatch(self.selected)
        end
    end
end

---描画.
function TitleScene:draw()
    gfx.fillRect(0, 0, Constants.UI.SCREEN.WIDTH - 1, Constants.UI.SCREEN.HEIGHT - 1)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("TSUKIKAGE", Constants.UI.SCREEN.CENTER_X, 34, kTextAlignment.center)
    gfx.drawTextAligned("JANTO", Constants.UI.SCREEN.CENTER_X, 58, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("1v1 MAHJONG / FOUR HAND MATCH", Constants.UI.SCREEN.CENTER_X, 89, kTextAlignment.center)
    local items = {
        { name = "PLAY YUI", type = Constants.Game.CPU_TYPE.YUI },
        { name = "PLAY HAIDO", type = Constants.Game.CPU_TYPE.HAIDO },
        { name = "HOW TO PLAY", type = Constants.UI.TITLE.LAST_ITEM },
    }
    for i, item in ipairs(items) do
        local y = Constants.UI.TITLE.ITEM_TOP + (i - 1) * Constants.UI.TITLE.ITEM_GAP
        if self.selected == item.type then
            gfx.fillRect(86, y - 2, 228, 18)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end
        gfx.drawTextAligned(item.name, Constants.UI.SCREEN.CENTER_X, y, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.drawTextAligned("UP/DOWN SELECT   A START", Constants.UI.SCREEN.CENTER_X, 207, kTextAlignment.center)
end

return TitleScene
