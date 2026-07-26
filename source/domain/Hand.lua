import "CoreLibs/object"

import "domain/Tile"

---@class Hand 手牌の状態を保持するオブジェクト.
---@field tiles number[] 手牌の牌.
---@field river number[] 捨て牌の牌.
---@field riichi boolean リーチしているかどうか.
Hand = class("Hand").extends() or Hand

---初期化.
function Hand:init()
    self.tiles = {}
    self.river = {}
    self.riichi = false
end

---手牌をリセット.
function Hand:reset()
    self.tiles = {}
    self.river = {}
    self.riichi = false
end

---手牌に牌を追加.
---@param tile number 追加する牌.
---@param sort boolean|nil 追加後にソートするかどうか.
function Hand:add(tile, sort)
    table.insert(self.tiles, tile)
    if sort ~= false then Tile.sort(self.tiles) end
end

---手牌から牌を削除.
---@param index number 削除する牌のインデックス.
---@return number|nil tile 削除された牌.
function Hand:removeAt(index)
    return table.remove(self.tiles, index)
end

---手牌から牌を捨てる.
---@param index number 捨てる牌のインデックス.
---@return number|nil tile 捨てられた牌.
function Hand:discardAt(index)
    local tile = self:removeAt(index)
    if tile ~= nil then table.insert(self.river, tile) end
    Tile.sort(self.tiles)
    return tile
end

---手牌をコピーする.
---@return Hand result コピーした手牌.
function Hand:copy()
    local result = Hand()
    result.tiles = Tile.copyArray(self.tiles)
    result.river = Tile.copyArray(self.river)
    result.riichi = self.riichi
    return result
end

return Hand
