import "CoreLibs/object"

class("Wall").extends()

function Wall:init(tiles)
    self.tiles = tiles or {}
    self.position = 0
    self.endPosition = #self.tiles
    self.doraIndicator = nil
end

function Wall:draw()
    if self.position >= self.endPosition then return nil end
    self.position = self.position + 1
    return self.tiles[self.position]
end

function Wall:remaining()
    return self.endPosition - self.position
end

function Wall:copy()
    local result = Wall()
    for i = 1, #self.tiles do result.tiles[i] = self.tiles[i] end
    result.position = self.position
    result.endPosition = self.endPosition
    result.doraIndicator = self.doraIndicator
    return result
end

return Wall
