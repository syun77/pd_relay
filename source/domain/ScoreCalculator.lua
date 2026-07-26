import "Constants"
import "domain/Tile"
import "domain/MahjongRules"

ScoreCalculator = {}

---スコア計算.
---@param hand number[] 手牌.
---@param riichi boolean リーチしているかどうか.
---@param doraIndicator number ドラ表示牌.
---@return table|nil info 計算結果. 完成形でない場合はnil
function ScoreCalculator.calculate(hand, riichi, doraIndicator)
    if not Rules.isCompleteShape(hand) then return nil end

    local dora = 0
    if doraIndicator ~= nil then
        local nextNumber = Tile.number(doraIndicator) % Constants.Game.TILE.TYPES_PER_SUIT + 1
        local nextTile = Tile.index(Tile.suit(doraIndicator), nextNumber)
        for _, tile in ipairs(hand) do
            if tile == nextTile then dora = dora + 1 end
        end
    end

    local best
    local function consider(info)
        if not best or info.han > best.han then best = info end
    end

    if Rules.isChiitoitsu(hand) then
        local han = 2 + dora + (riichi and 1 or 0)
        consider({
            han = han,
            names = (riichi and "RIICHI / " or "") .. "CHIITOI" .. (dora > 0 and " / DORA x" .. dora or ""),
            dora = dora
        })
    end

    for _, decomposition in ipairs(Rules.collectStandardDecompositions(hand, 24)) do
        local names, yakuHan = {}, 0
        if riichi then table.insert(names, "RIICHI"); yakuHan = yakuHan + 1 end
        if Rules.allSimple(hand) then table.insert(names, "TANYAO"); yakuHan = yakuHan + 1 end

        local pinfu = true
        for _, meld in ipairs(decomposition.melds) do
            if meld.kind ~= "sequence" then pinfu = false end
        end
        if pinfu then table.insert(names, "PINFU"); yakuHan = yakuHan + 1 end
        if Rules.sequencePair(decomposition) then table.insert(names, "IIPEIKOU"); yakuHan = yakuHan + 1 end
        if Rules.oneSuit(hand) then table.insert(names, "CHINITSU"); yakuHan = yakuHan + 5 end

        if yakuHan > 0 then
            if dora > 0 then table.insert(names, "DORA x" .. dora) end
            consider({ han = yakuHan + dora, names = table.concat(names, " / "), dora = dora })
        end
    end

    return best
end

return ScoreCalculator
