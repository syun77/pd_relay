import "scenes/Scene"

class("TitleScene").extends(Scene)

function TitleScene:init(context)
    TitleScene.super.init(self, context)
    self.selected = 1
end

function TitleScene:update(input, now)
    if input:pressed("UP") or input:pressed("LEFT") then
        self.selected = math.max(1, self.selected - 1)
    elseif input:pressed("DOWN") or input:pressed("RIGHT") then
        self.selected = math.min(3, self.selected + 1)
    elseif input:released("MENU") then
        self.context.sceneManager:change(self.context.helpScene())
    elseif input:released("A") then
        if self.selected == 3 then
            self.context.sceneManager:change(self.context.helpScene())
        else
            self.context:startMatch(self.selected)
        end
    end
end

function TitleScene:draw()
    local gfx = playdate.graphics
    gfx.fillRect(0, 0, 399, 239)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("TSUKIKAGE", 200, 34, kTextAlignment.center)
    gfx.drawTextAligned("JANTO", 200, 58, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("1v1 MAHJONG / FOUR HAND MATCH", 200, 89, kTextAlignment.center)
    for i, item in ipairs({"PLAY YUI", "PLAY HAIDO", "HOW TO PLAY"}) do
        local y = 122 + (i - 1) * 22
        if self.selected == i then
            gfx.fillRect(86, y - 2, 228, 18)
            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        end
        gfx.drawTextAligned(item, 200, y, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.drawTextAligned("UP/DOWN SELECT   A START", 200, 207, kTextAlignment.center)
end

return TitleScene
