--[[
========================================================
	牌モジュール.
========================================================
]]
import "Constants"

---@class Tile 牌の種類を表すモジュール.
Tile = {}

Tile.suitNames = { "M", "P", "S" }
Tile.suitNamesLong = { "MAN", "PIN", "SOU" }

---タイル番号からスーツを取得.
---@param tile number タイル番号.
---@return number suit スーツ番号.
function Tile.suit(tile)
    return math.floor(tile / Constants.Game.TILE.TYPES_PER_SUIT) + 1
end

---タイル番号から数値を取得.
---@param tile number タイル番号.
---@return number number 数値.
function Tile.number(tile)
    return tile % Constants.Game.TILE.TYPES_PER_SUIT + 1
end

---スーツと数値からタイル番号を取得.
---@param suit number スーツ番号.
---@param number number 数値.
---@return number tile タイル番号.
function Tile.index(suit, number)
    return (suit - 1) * Constants.Game.TILE.TYPES_PER_SUIT + number - 1
end

---牌の値を文字列に変換.
---@param tile number タイル番号.
---@return string text 文字列表現.
function Tile.text(tile)
    return tostring(Tile.number(tile)) .. Tile.suitNames[Tile.suit(tile)]
end

---牌の配列をコピーして配列を返す.
---@param source number[] コピー元の配列.
---@return number[] result コピーした配列.
function Tile.copyArray(source)
    local result = {}
    for i = 1, #source do result[i] = source[i] end
    return result
end

---牌のソートを行う.
---@param tiles number[] ソートする牌の配列.
---@return number[] tiles ソート後の牌の配列.
function Tile.sort(tiles)
    table.sort(tiles, function(a, b) return a < b end)
end

return Tile
