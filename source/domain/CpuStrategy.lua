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
        if number - distance >= 1 and counts[tile - distance] > 0 and Tile.suit(tile - distance) == suit then
            value = value + (3 - distance)
        end
        if number + distance <= 9 and counts[tile + distance] > 0 and Tile.suit(tile + distance) == suit then
            value = value + (3 - distance)
        end
    end

    if number == 1 or number == 9 then value = value - 1 end
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
