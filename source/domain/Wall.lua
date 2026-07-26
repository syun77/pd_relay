import "CoreLibs/object"

---@class Wall 山の状態を保持するオブジェクト.
---@field tiles number[] 山の牌.
---@field position number 現在の山の位置.
---@field endPosition number 山の終端位置.
---@field doraIndicator number ドラ表示牌.
Wall = class("Wall").extends() or Wall

---初期化.
---@param tiles number[] 山の牌.
function Wall:init(tiles)
    self.tiles = tiles or {}
    self.position = 0
    self.endPosition = #self.tiles
    self.doraIndicator = nil
end

---牌を積もる.
---@return number|nil tile 積もった牌.
function Wall:draw()
    if self.position >= self.endPosition then return nil end
    self.position = self.position + 1
    return self.tiles[self.position]
end

---残りの牌の枚数を取得.
---@return number 残りの牌の枚数.
function Wall:remaining()
    return self.endPosition - self.position
end

---山をコピーして返す.
---@return Wall result コピーした山.
function Wall:copy()
    local result = Wall()
    for i = 1, #self.tiles do result.tiles[i] = self.tiles[i] end
    result.position = self.position
    result.endPosition = self.endPosition
    result.doraIndicator = self.doraIndicator
    return result
end

return Wall
