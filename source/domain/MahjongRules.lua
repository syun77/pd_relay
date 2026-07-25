import "domain/Tile"

Rules = {}

function Rules.countsFor(hand)
    local counts = {}
    for i = 0, 26 do counts[i] = 0 end
    for _, tile in ipairs(hand) do counts[tile] = counts[tile] + 1 end
    return counts
end

function Rules.containsTile(hand, tile)
    for _, value in ipairs(hand) do
        if value == tile then return true end
    end
    return false
end

function Rules.appendTile(hand, tile)
    local result = Tile.copyArray(hand)
    table.insert(result, tile)
    Tile.sort(result)
    return result
end

function Rules.isChiitoitsu(hand)
    if #hand ~= 14 then return false end
    local counts = Rules.countsFor(hand)
    local pairs = 0
    for i = 0, 26 do
        if counts[i] == 2 then pairs = pairs + 1
        elseif counts[i] ~= 0 then return false end
    end
    return pairs == 7
end

function Rules.collectStandardDecompositions(hand, limit)
    if #hand ~= 14 then return {} end

    local counts = Rules.countsFor(hand)
    local result = {}

    local function walk(remaining, pair, melds)
        if #result >= (limit or 24) then return end
        if remaining == 0 then
            if pair and #melds == 4 then
                local meldCopy = {}
                for i, meld in ipairs(melds) do
                    meldCopy[i] = { kind = meld.kind, tiles = Tile.copyArray(meld.tiles) }
                end
                table.insert(result, { pair = pair, melds = meldCopy })
            end
            return
        end

        local first
        for i = 0, 26 do
            if counts[i] > 0 then first = i; break end
        end
        if first == nil then return end

        if not pair and counts[first] >= 2 then
            counts[first] = counts[first] - 2
            walk(remaining - 2, first, melds)
            counts[first] = counts[first] + 2
        end

        if #melds >= 4 then return end
        if counts[first] >= 3 then
            counts[first] = counts[first] - 3
            table.insert(melds, { kind = "triplet", tiles = { first, first, first } })
            walk(remaining - 3, pair, melds)
            table.remove(melds)
            counts[first] = counts[first] + 3
        end

        local number, suit = Tile.number(first), Tile.suit(first)
        if number <= 7 then
            local a, b = first + 1, first + 2
            if Tile.suit(a) == suit and Tile.suit(b) == suit and counts[a] > 0 and counts[b] > 0 then
                counts[first], counts[a], counts[b] = counts[first] - 1, counts[a] - 1, counts[b] - 1
                table.insert(melds, { kind = "sequence", tiles = { first, a, b } })
                walk(remaining - 3, pair, melds)
                table.remove(melds)
                counts[first], counts[a], counts[b] = counts[first] + 1, counts[a] + 1, counts[b] + 1
            end
        end
    end

    walk(14, nil, {})
    return result
end

function Rules.isCompleteShape(hand)
    return #hand == 14 and (Rules.isChiitoitsu(hand) or #Rules.collectStandardDecompositions(hand, 1) > 0)
end

function Rules.allSimple(hand)
    for _, tile in ipairs(hand) do
        if Tile.number(tile) == 1 or Tile.number(tile) == 9 then return false end
    end
    return true
end

function Rules.oneSuit(hand)
    if #hand == 0 then return false end
    local suit = Tile.suit(hand[1])
    for _, tile in ipairs(hand) do
        if Tile.suit(tile) ~= suit then return false end
    end
    return true
end

function Rules.sequencePair(decomposition)
    local seen = {}
    for _, meld in ipairs(decomposition.melds) do
        if meld.kind == "sequence" then
            local key = meld.tiles[1]
            seen[key] = (seen[key] or 0) + 1
        end
    end
    for _, count in pairs(seen) do
        if count >= 2 then return true end
    end
    return false
end

function Rules.hasShapeDraw(hand13)
    for tile = 0, 26 do
        if Rules.isCompleteShape(Rules.appendTile(hand13, tile)) then return true end
    end
    return false
end

function Rules.canRiichiAfterDiscard(hand14, index)
    local candidate = Tile.copyArray(hand14)
    table.remove(candidate, index)
    return Rules.hasShapeDraw(candidate)
end

return Rules
