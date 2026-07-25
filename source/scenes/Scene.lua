import "CoreLibs/object"

Scene = class("Scene").extends() or Scene

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
