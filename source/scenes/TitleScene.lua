import "Constants"
import "scenes/Scene"

TitleScene = class("TitleScene").extends(Scene) or TitleScene

function TitleScene:init(context)
    TitleScene.super.init(self, context)
    self.selected = Constants.UI.TITLE.FIRST_ITEM
end

function TitleScene:update(input, now)
    if input:pressed("UP") or input:pressed("LEFT") then
        self.selected = math.max(Constants.UI.TITLE.FIRST_ITEM, self.selected - 1)
    elseif input:pressed("DOWN") or input:pressed("RIGHT") then
        self.selected = math.min(Constants.UI.TITLE.LAST_ITEM, self.selected + 1)
    elseif input:released("MENU") then
        self.context.sceneManager:change(self.context.helpScene())
    elseif input:released("A") then
        if self.selected == Constants.UI.TITLE.HELP_ITEM then
            self.context.sceneManager:change(self.context.helpScene())
        else
            self.context:startMatch(self.selected)
        end
    end
end

function TitleScene:draw()
    local gfx = playdate.graphics
    gfx.fillRect(0, 0, Constants.UI.SCREEN.WIDTH - 1, Constants.UI.SCREEN.HEIGHT - 1)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("TSUKIKAGE", Constants.UI.SCREEN.CENTER_X, 34, kTextAlignment.center)
    gfx.drawTextAligned("JANTO", Constants.UI.SCREEN.CENTER_X, 58, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("1v1 MAHJONG / FOUR HAND MATCH", Constants.UI.SCREEN.CENTER_X, 89, kTextAlignment.center)
    for i, item in ipairs({"PLAY YUI", "PLAY HAIDO", "HOW TO PLAY"}) do
        local y = Constants.UI.TITLE.ITEM_TOP + (i - 1) * Constants.UI.TITLE.ITEM_GAP
        if self.selected == i then
            gfx.fillRect(86, y - 2, 228, 18)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end
        gfx.drawTextAligned(item, Constants.UI.SCREEN.CENTER_X, y, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.drawTextAligned("UP/DOWN SELECT   A START", Constants.UI.SCREEN.CENTER_X, 207, kTextAlignment.center)
end

return TitleScene
