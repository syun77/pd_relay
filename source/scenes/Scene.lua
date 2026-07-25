import "CoreLibs/object"

class("Scene").extends()

function Scene:init(context)
    self.context = context
end

function Scene:enter()
end

function Scene:leave()
end

function Scene:update(input, now)
end

function Scene:draw()
end

return Scene
