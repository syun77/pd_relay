import "Constants"

Tile = {}

Tile.suitNames = { "M", "P", "S" }
Tile.suitNamesLong = { "MAN", "PIN", "SOU" }

function Tile.suit(tile)
    return math.floor(tile / Constants.Game.TILE.TYPES_PER_SUIT) + 1
end

function Tile.number(tile)
    return tile % Constants.Game.TILE.TYPES_PER_SUIT + 1
end

function Tile.index(suit, number)
    return (suit - 1) * Constants.Game.TILE.TYPES_PER_SUIT + number - 1
end

function Tile.text(tile)
    return tostring(Tile.number(tile)) .. Tile.suitNames[Tile.suit(tile)]
end

function Tile.copyArray(source)
    local result = {}
    for i = 1, #source do result[i] = source[i] end
    return result
end

function Tile.sort(tiles)
    table.sort(tiles, function(a, b) return a < b end)
end

return Tile
