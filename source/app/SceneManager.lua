import "CoreLibs/object"

class("SceneManager").extends()

function SceneManager:init()
    self.current = nil
end

function SceneManager:change(scene)
    if self.current then self.current:leave() end
    self.current = scene
    self.current:enter()
end

function SceneManager:update(input, now)
    if self.current then self.current:update(input, now) end
end

function SceneManager:draw()
    if self.current then self.current:draw() end
end

return SceneManager
