import "CoreLibs/object"

import "domain/Tile"

class("Hand").extends()

function Hand:init()
    self.tiles = {}
    self.river = {}
    self.riichi = false
end

function Hand:reset()
    self.tiles = {}
    self.river = {}
    self.riichi = false
end

function Hand:add(tile, sort)
    table.insert(self.tiles, tile)
    if sort ~= false then Tile.sort(self.tiles) end
end

function Hand:removeAt(index)
    return table.remove(self.tiles, index)
end

function Hand:discardAt(index)
    local tile = self:removeAt(index)
    if tile ~= nil then table.insert(self.river, tile) end
    Tile.sort(self.tiles)
    return tile
end

function Hand:copy()
    local result = Hand()
    result.tiles = Tile.copyArray(self.tiles)
    result.river = Tile.copyArray(self.river)
    result.riichi = self.riichi
    return result
end

return Hand
