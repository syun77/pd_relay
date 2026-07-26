import "scenes/Scene"

HelpScene = class("HelpScene").extends(Scene) or HelpScene

function HelpScene:update(input, now)
    if input:released("A") or input:released("B") or input:released("MENU") then
        self.context.sceneManager:change(self.context:titleScene())
    end
end

function HelpScene:draw()
    local gfx = playdate.graphics
    gfx.drawText("HOW TO PLAY", 12, 8)
    gfx.drawText("A CUT / CONFIRM       B CANCEL", 12, 35)
    gfx.drawText("LEFT/RIGHT  SELECT TILE", 12, 55)
    gfx.drawText("UP  INSPECT RIVERS     DOWN  HINT", 12, 75)
    gfx.drawText("A-HOLD  RIICHI         B-HOLD  ABILITY", 12, 95)
    gfx.drawText("REVERSE rewinds your last draw + cut.", 12, 125)
    gfx.drawText("The next draw changes. RIICHI locks.", 12, 145)
    gfx.drawText("Win with RIICHI, TANYAO, PINFU,", 12, 170)
    gfx.drawText("IIPEIKOU, CHIITOI or CHINITSU.", 12, 188)
    gfx.drawText("A/B: BACK", 12, 222)
end

return HelpScene
