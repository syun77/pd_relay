import "Constants"
import "domain/Tile"
import "domain/MahjongRules"

CpuStrategy = {}

function CpuStrategy.keepValue(hand, index, targetSuit)
    local tile = hand[index]
    local counts = Rules.countsFor(hand)
    local value = 0
    if counts[tile] >= 2 then value = value + 5 end

    local number, suit = Tile.number(tile), Tile.suit(tile)
    for distance = 1, 2 do
        if suit == Constants.Game.SUIT.HONOR then break end
        if number - distance >= 1 and counts[tile - distance] > 0 and Tile.suit(tile - distance) == suit then
            value = value + (3 - distance)
        end
        if number + distance <= Constants.Game.TILE.TYPES_PER_SUIT
            and counts[tile + distance] > 0
            and Tile.suit(tile + distance) == suit then
            value = value + (3 - distance)
        end
    end

    if suit == Constants.Game.SUIT.HONOR
        or number == 1
        or number == Constants.Game.TILE.TYPES_PER_SUIT then
        value = value - 1
    end
    if targetSuit and suit == targetSuit then value = value + 4 end
    return value
end

function CpuStrategy.discardIndex(hand, targetSuit)
    local bestIndex, bestValue = 1, math.huge
    for i = 1, #hand do
        local value = CpuStrategy.keepValue(hand, i, targetSuit)
        if value < bestValue then bestIndex, bestValue = i, value end
    end
    return bestIndex
end

return CpuStrategy
