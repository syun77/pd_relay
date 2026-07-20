import "CoreLibs/graphics"
import "CoreLibs/ui"

local pd <const> = playdate
local gfx <const> = pd.graphics

-- 月影雀闘 / Tsukikage Janto
-- A compact 1v1 mahjong prototype for Playdate.

local W, H = 400, 240
local suitNames = { "M", "P", "S" }
local suitNamesLong = { "MAN", "PIN", "SOU" }
local phases = { TITLE=1, HELP=2, PLAYER=3, TSUMO=4, RON=5, CPU=6, HAND_RESULT=7, MATCH_RESULT=8, ABILITY=9, CPU_RON=10 }
local phase = phases.TITLE
local menuItem = 1
local cpuType = 1 -- 1: Yui, 2: Haido
local handNo = 1
local dealer = 1 -- 1: player, 2: CPU
local scores = { 25000, 25000 }
local player = { hand={}, river={}, riichi=false }
local cpu = { hand={}, river={}, riichi=false }
local wall = {}
local wallPos = 0
local wallEnd = 0
local selected = 1
local inspectMode = false
local hintMode = false
local pressure = 0
local targetSuit = nil
local cpuAbilityUsed = false
local reverseUsed = false
local reverseReady = false
local reverseSnapshot = nil
local toast = ""
local toastUntil = 0
local resultText = ""
local resultDetail = ""
local pendingRonTile = nil
local flashUntil = 0
local cpuThinkUntil = 0
local riichiAutoDiscardAt = 0
local leftRepeatAt, rightRepeatAt = 0, 0
local cpuRonTile = nil
local cpuRonInfo = nil
local cpuRonUntil = 0
local resultInfo = nil
local resultWinTile = nil
local resultPoints = 0
local resultHand = nil
local aDownAt, bDownAt = nil, nil
local nowMs = 0

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function moveHandCursor(delta)
    if #player.hand == 0 then return end
    selected = ((selected - 1 + delta) % #player.hand) + 1
end

local function copyArray(source)
    local result = {}
    for i=1,#source do result[i] = source[i] end
    return result
end

local function tileSuit(tile)
    return math.floor(tile / 9) + 1
end

local function tileNumber(tile)
    return tile % 9 + 1
end

local function tileText(tile)
    return tostring(tileNumber(tile)) .. suitNames[tileSuit(tile)]
end

local function tileIndex(suit, number)
    return (suit - 1) * 9 + number - 1
end

local function sortHand(hand)
    table.sort(hand, function(a,b) return a < b end)
end

local function showToast(message, duration)
    toast = message
    toastUntil = nowMs + (duration or 1500)
end

local function shuffle(deck)
    for i=#deck,2,-1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function makeWall()
    local deck = {}
    for tile=0,26 do
        for _=1,4 do table.insert(deck, tile) end
    end
    shuffle(deck)
    return deck
end

local function countsFor(hand)
    local counts = {}
    for i=0,26 do counts[i] = 0 end
    for _,tile in ipairs(hand) do counts[tile] = counts[tile] + 1 end
    return counts
end

local function containsTile(hand, tile)
    for _,t in ipairs(hand) do if t == tile then return true end end
    return false
end

local function removeOne(hand, tile)
    for i,t in ipairs(hand) do
        if t == tile then table.remove(hand, i); return true end
    end
    return false
end

local function isChiitoitsu(hand)
    if #hand ~= 14 then return false end
    local c = countsFor(hand)
    local pairs = 0
    for i=0,26 do
        if c[i] == 2 then pairs = pairs + 1
        elseif c[i] ~= 0 then return false end
    end
    return pairs == 7
end

local function collectStandardDecompositions(hand, limit)
    if #hand ~= 14 then return {} end
    local counts = countsFor(hand)
    local result = {}
    local function walk(remaining, pair, melds)
        if #result >= (limit or 24) then return end
        if remaining == 0 then
            if pair and #melds == 4 then
                local meldCopy = {}
                for i,m in ipairs(melds) do
                    meldCopy[i] = { kind=m.kind, tiles=copyArray(m.tiles) }
                end
                table.insert(result, { pair=pair, melds=meldCopy })
            end
            return
        end
        local first = nil
        for i=0,26 do if counts[i] > 0 then first = i; break end end
        if first == nil then return end

        if not pair and counts[first] >= 2 then
            counts[first] = counts[first] - 2
            walk(remaining - 2, first, melds)
            counts[first] = counts[first] + 2
        end
        if #melds >= 4 then return end
        if counts[first] >= 3 then
            counts[first] = counts[first] - 3
            table.insert(melds, { kind="triplet", tiles={first,first,first} })
            walk(remaining - 3, pair, melds)
            table.remove(melds)
            counts[first] = counts[first] + 3
        end
        local n = tileNumber(first)
        local s = tileSuit(first)
        if n <= 7 then
            local a, b = first + 1, first + 2
            if tileSuit(a) == s and tileSuit(b) == s and counts[a] > 0 and counts[b] > 0 then
                counts[first], counts[a], counts[b] = counts[first]-1, counts[a]-1, counts[b]-1
                table.insert(melds, { kind="sequence", tiles={first,a,b} })
                walk(remaining - 3, pair, melds)
                table.remove(melds)
                counts[first], counts[a], counts[b] = counts[first]+1, counts[a]+1, counts[b]+1
            end
        end
    end
    walk(14, nil, {})
    return result
end

local function isCompleteShape(hand)
    if #hand ~= 14 then return false end
    if isChiitoitsu(hand) then return true end
    return #collectStandardDecompositions(hand, 1) > 0
end

local function allSimple(hand)
    for _,tile in ipairs(hand) do
        if tileNumber(tile) == 1 or tileNumber(tile) == 9 then return false end
    end
    return true
end

local function oneSuit(hand)
    local s = tileSuit(hand[1])
    for _,tile in ipairs(hand) do if tileSuit(tile) ~= s then return false end end
    return true
end

local function sequencePair(decomp)
    local seen = {}
    for _,meld in ipairs(decomp.melds) do
        if meld.kind == "sequence" then
            local key = meld.tiles[1]
            seen[key] = (seen[key] or 0) + 1
        end
    end
    for _,n in pairs(seen) do if n >= 2 then return true end end
    return false
end

local function scoreHand(hand, riichi)
    if not isCompleteShape(hand) then return nil end
    local best = nil
    local function consider(info)
        if not best or info.han > best.han then best = info end
    end
    local dora = 0
    if wall.doraIndicator then
        local indicator = wall.doraIndicator
        local nextNumber = tileNumber(indicator) % 9 + 1
        local nextTile = tileIndex(tileSuit(indicator), nextNumber)
        for _,tile in ipairs(hand) do if tile == nextTile then dora = dora + 1 end end
    end
    if isChiitoitsu(hand) then
        local han = 2 + dora
        if riichi then han = han + 1 end
        consider({han=han, names=(riichi and "RIICHI / " or "") .. "CHIITOI" .. (dora > 0 and " / DORA x" .. dora or ""), dora=dora})
    end
    local decomps = collectStandardDecompositions(hand, 24)
    for _,decomp in ipairs(decomps) do
        local names, han = {}, 0
        local yakuHan = 0
        if riichi then table.insert(names, "RIICHI"); yakuHan = yakuHan + 1 end
        if allSimple(hand) then table.insert(names, "TANYAO"); yakuHan = yakuHan + 1 end
        local pinfu = true
        for _,meld in ipairs(decomp.melds) do if meld.kind ~= "sequence" then pinfu = false end end
        if pinfu then table.insert(names, "PINFU"); yakuHan = yakuHan + 1 end
        if sequencePair(decomp) then table.insert(names, "IIPEIKOU"); yakuHan = yakuHan + 1 end
        if oneSuit(hand) then table.insert(names, "CHINITSU"); yakuHan = yakuHan + 5 end
        if yakuHan > 0 then
            han = yakuHan + dora
            if dora > 0 then table.insert(names, "DORA x" .. dora) end
            consider({han=han, names=table.concat(names, " / "), dora=dora})
        end
    end
    return best
end

local function appendTile(hand, tile)
    local result = copyArray(hand)
    table.insert(result, tile)
    sortHand(result)
    return result
end

local function hasWinningDraw(hand13, riichi)
    for tile=0,26 do
        local candidate = appendTile(hand13, tile)
        if scoreHand(candidate, riichi) then return tile end
    end
    return nil
end

local function hasShapeDraw(hand13)
    for tile=0,26 do if isCompleteShape(appendTile(hand13, tile)) then return true end end
    return false
end

local function canRiichiAfterDiscard(hand14, index)
    local candidate = copyArray(hand14)
    table.remove(candidate, index)
    return hasShapeDraw(candidate)
end

local function drawFromWall()
    if wallPos >= wallEnd then return nil end
    wallPos = wallPos + 1
    return wall[wallPos]
end

local function updatePressure()
    local c = countsFor(cpu.hand)
    local value = 0
    for i=0,26 do
        if c[i] >= 2 then value = value + 1 end
        if c[i] >= 3 then value = value + 1 end
        local n, s = tileNumber(i), tileSuit(i)
        if n <= 7 and c[i] > 0 and c[i+1] > 0 then value = value + 1 end
        if n <= 6 and c[i] > 0 and c[i+2] > 0 then value = value + 1 end
    end
    if targetSuit then
        for _,tile in ipairs(cpu.hand) do if tileSuit(tile) == targetSuit then value = value + 1 end end
    end
    pressure = clamp(math.floor(value / 4) + (cpuAbilityUsed and 1 or 0), 0, 5)
end

local function tileKeepValue(hand, index)
    local tile = hand[index]
    local c = countsFor(hand)
    local value = 0
    if c[tile] >= 2 then value = value + 5 end
    local n, s = tileNumber(tile), tileSuit(tile)
    for d=1,2 do
        if n-d >= 1 and c[tile-d] > 0 and tileSuit(tile-d) == s then value = value + (3-d) end
        if n+d <= 9 and c[tile+d] > 0 and tileSuit(tile+d) == s then value = value + (3-d) end
    end
    if n == 1 or n == 9 then value = value - 1 end
    if targetSuit and s == targetSuit then value = value + 4 end
    return value
end

local function cpuDiscardIndex()
    local bestIndex, bestValue = 1, 999
    for i=1,#cpu.hand do
        local value = tileKeepValue(cpu.hand, i)
        if value < bestValue then bestIndex, bestValue = i, value end
    end
    return bestIndex
end

local function setupHand()
    wall = makeWall()
    wallPos = 26
    wallEnd = #wall -- full deck while dealing
    player = {hand={}, river={}, riichi=false}
    cpu = {hand={}, river={}, riichi=false}
    for _=1,13 do table.insert(player.hand, drawFromWall()) end
    for _=1,13 do table.insert(cpu.hand, drawFromWall()) end
    -- Keep the active wall short: about 50 draws remain after the deal.
    wallEnd = math.min(#wall, wallPos + 50)
    wall.doraIndicator = wall[wallEnd + 1] or wall[1]
    sortHand(player.hand); sortHand(cpu.hand)
    selected = 1
    inspectMode, hintMode = false, false
    pressure, targetSuit = 0, nil
    cpuAbilityUsed = false
    reverseUsed, reverseReady = false, false
    reverseSnapshot = nil
    riichiAutoDiscardAt = 0
    cpuRonTile, cpuRonInfo, cpuRonUntil = nil, nil, 0
    phase = phases.PLAYER
    beginPlayerDraw()
end

function beginPlayerDraw()
    if wallPos >= wallEnd then
        resultText, resultDetail = "DRAW HAND", "The wall is empty. No points move."
        phase = phases.HAND_RESULT
        return
    end
    reverseSnapshot = { hand=copyArray(player.hand), river=copyArray(player.river), wall=copyArray(wall), wallPos=wallPos, doraIndicator=wall.doraIndicator }
    reverseReady = false
    local tile = drawFromWall()
    if tile == nil then
        resultText, resultDetail = "DRAW HAND", "The wall is empty."
        phase = phases.HAND_RESULT
        return
    end
    table.insert(player.hand, tile)
    -- Keep the drawn tile at the far right so it is immediately recognizable.
    selected = clamp(selected, 1, #player.hand)
    local info = scoreHand(player.hand, player.riichi)
    if info then
        phase = phases.TSUMO
    else
        phase = phases.PLAYER
        if player.riichi then
            selected = #player.hand
            riichiAutoDiscardAt = nowMs + 500
        end
    end
    updatePressure()
end

local function applyHandScore(winner, points)
    if winner == 1 then scores[1] = scores[1] + points; scores[2] = scores[2] - points
    elseif winner == 2 then scores[1] = scores[1] - points; scores[2] = scores[2] + points end
end

local function finishHand(winner, winType, winTile, info)
    local points = 0
    if info then points = clamp(1000 * (2 ^ math.max(0, info.han - 1)), 1000, 8000) end
    resultInfo, resultWinTile, resultPoints = info, winTile, points
    resultHand = nil
    if winner == 2 then
        resultHand = copyArray(cpu.hand)
        if winType == "RON" then table.insert(resultHand, winTile); sortHand(resultHand) end
    end
    if winner ~= 0 then applyHandScore(winner, points) end
    if winner == 1 then
        resultText = (winType == "TSUMO" and "PLAYER TSUMO" or "PLAYER RON")
    elseif winner == 2 then resultText = "CPU " .. (winType or "WIN")
    else resultText = "DRAW HAND" end
    if info then
        resultDetail = info.names .. "  +" .. points .. "\n" .. tileText(winTile or 0)
    else
        resultDetail = "No points move.\nPress A for the next hand."
    end
    phase = phases.HAND_RESULT
    flashUntil = nowMs + 800
end

local function beginCpuRon(tile, info)
    cpuRonTile, cpuRonInfo = tile, info
    cpuRonUntil = nowMs + 900
    phase = phases.CPU_RON
    flashUntil = nowMs + 900
end

local function advanceHand()
    if handNo >= 4 then phase = phases.MATCH_RESULT; return end
    local handWinner = resultText:find("PLAYER") and 1 or (resultText:find("CPU") and 2 or 0)
    if handWinner ~= dealer then dealer = 3 - dealer end
    handNo = handNo + 1
    setupHand()
end

local function doReverse()
    if reverseUsed then showToast("REVERSE USED", 1200); return end
    if not reverseReady or not reverseSnapshot then showToast("CUT A TILE FIRST", 1200); return end
    local snap = reverseSnapshot
    player.hand = copyArray(snap.hand)
    player.river = copyArray(snap.river)
    wall = copyArray(snap.wall)
    wall.doraIndicator = snap.doraIndicator
    wallPos = snap.wallPos
    if wallPos + 1 <= wallEnd then
        wall[wallPos + 1], wall[wallPos + 2] = wall[wallPos + 2] or wall[wallPos + 1], wall[wallPos + 1]
    end
    reverseUsed = true
    reverseReady = false
    player.riichi = false
    riichiAutoDiscardAt = 0
    selected = clamp(selected, 1, #player.hand)
    phase = phases.PLAYER
    showToast("REWOUND / RIICHI LOCKED", 1600)
    flashUntil = nowMs + 500
    beginPlayerDraw()
end

local function cpuTakeTurn()
    if cpuType == 2 and not cpuAbilityUsed then
        cpuAbilityUsed = true
        targetSuit = math.random(1,3)
        for i=wallPos+1,wallEnd do
            if tileSuit(wall[i]) == targetSuit then
                wall[wallPos+1], wall[i] = wall[i], wall[wallPos+1]
                break
            end
        end
        showToast("HAIDO: " .. suitNamesLong[targetSuit] .. " PULL", 1300)
        flashUntil = nowMs + 450
    end
    local tile = drawFromWall()
    if not tile then finishHand(0, nil, nil, nil); return end
    table.insert(cpu.hand, tile)
    sortHand(cpu.hand)
    local info = scoreHand(cpu.hand, cpu.riichi)
    if info then finishHand(2, "TSUMO", tile, info); return end
    local index = cpuDiscardIndex()
    local discard = table.remove(cpu.hand, index)
    table.insert(cpu.river, discard)
    updatePressure()
    local ronInfo = scoreHand(appendTile(player.hand, discard), player.riichi)
    if ronInfo and not containsTile(player.river, discard) then
        pendingRonTile = discard
        phase = phases.RON
    else
        beginPlayerDraw()
    end
end

local function playerDiscard(isRiichi)
    if #player.hand ~= 14 then return end
    if isRiichi and (reverseUsed or player.riichi or not canRiichiAfterDiscard(player.hand, selected)) then
        showToast("RIICHI NOT AVAILABLE", 1100); return
    end
    local discard = table.remove(player.hand, selected)
    -- The drawn tile stays on the right until a discard; then restore a tidy hand.
    sortHand(player.hand)
    riichiAutoDiscardAt = 0
    table.insert(player.river, discard)
    if isRiichi then player.riichi = true end
    local ronInfo = scoreHand(appendTile(cpu.hand, discard), cpu.riichi)
    if ronInfo then
        beginCpuRon(discard, ronInfo)
        return
    end
    reverseReady = true
    phase = phases.CPU
    cpuThinkUntil = nowMs + 350
    if isRiichi then showToast("RIICHI!", 900) end
end

local function startSelected()
    if menuItem == 3 then phase = phases.HELP; return end
    cpuType = menuItem
    handNo, dealer = 1, 1
    scores = {25000,25000}
    setupHand()
end

local function drawHeader()
    gfx.drawText("TSUKIKAGE JANTO", 8, 3)
    gfx.drawText("E" .. handNo .. "  " .. (dealer == 1 and "OYA" or "CPU OYA"), 160, 3)
    gfx.drawText("YOU " .. scores[1], 8, 17)
    gfx.drawText("CPU " .. scores[2], 108, 17)
    gfx.drawText("D:" .. tileText(wall.doraIndicator or 0), 306, 3)
    gfx.drawText("PRESS", 235, 17)
    for i=1,5 do
        if i <= pressure then gfx.fillRect(280 + (i-1)*18, 18, 14, 7)
        else gfx.drawRect(280 + (i-1)*18, 18, 14, 7) end
    end
end

local function drawManMark(number, x, y, w, h, small)
    local cx = x + math.floor(w / 2)
    local numberY = y + (small and 0 or 1)
    gfx.drawTextAligned(tostring(number), cx, numberY, kTextAlignment.center)
    local top = y + (small and 9 or 13)
    local span = small and 4 or 6
    local foot = small and 8 or 10
    -- A compact, kanji-like "萬" mark. It stays legible in Playdate's 1-bit display.
    gfx.drawLine(cx-span, top, cx+span, top)
    gfx.drawLine(cx, top-2, cx, top+7)
    gfx.drawLine(cx-span+1, top+3, cx+span-1, top+3)
    gfx.drawLine(cx-span, top+7, cx+span, top+7)
    gfx.drawLine(cx-span+2, top+7, cx-span+2, top+foot)
    gfx.drawLine(cx+span-2, top+7, cx+span-2, top+foot)
end

local pipLayouts = {
    [1]={{2,2}}, [2]={{1,1},{3,3}}, [3]={{1,1},{2,2},{3,3}},
    [4]={{1,1},{3,1},{1,3},{3,3}}, [5]={{1,1},{3,1},{2,2},{1,3},{3,3}},
    [6]={{1,1},{3,1},{1,2},{3,2},{1,3},{3,3}},
    [7]={{1,1},{3,1},{2,2},{1,3},{3,3},{1,4},{3,4}},
    [8]={{1,1},{3,1},{1,2},{3,2},{1,3},{3,3},{1,4},{3,4}},
    [9]={{1,1},{2,1},{3,1},{1,2},{2,2},{3,2},{1,3},{2,3},{3,3}}
}

local function drawPinMark(number, x, y, w, h, small)
    local positions = pipLayouts[number]
    local cols, rows = 3, (number >= 7 and number <= 8) and 4 or 3
    local left = x + (small and 5 or 6)
    local right = x + w - (small and 5 or 6)
    local top = y + (small and 4 or 5)
    local bottom = y + h - (small and 4 or 5)
    local radius = small and 1 or 2
    for _,point in ipairs(positions) do
        local px = left + math.floor((point[1]-1) * (right-left) / (cols-1))
        local py = top + math.floor((point[2]-1) * (bottom-top) / math.max(1, rows-1))
        gfx.fillCircleAtPoint(px, py, radius)
        if not small and radius > 1 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(px, py, 1)
            gfx.setColor(gfx.kColorBlack)
        end
    end
end

local function drawSouMark(number, x, y, w, h, small)
    local cols = number <= 3 and number or 3
    local rows = math.ceil(number / cols)
    local left = x + (small and 6 or 6)
    local right = x + w - (small and 6 or 6)
    local top = y + (small and 3 or 4)
    local bottom = y + h - (small and 3 or 4)
    for i=1,number do
        local col = (i-1) % cols
        local row = math.floor((i-1) / cols)
        local px = cols == 1 and math.floor((left+right)/2) or left + math.floor(col * (right-left) / (cols-1))
        local py = rows == 1 and top + 1 or top + math.floor(row * (bottom-top-5) / math.max(1, rows-1))
        local stem = small and 4 or 6
        gfx.drawLine(px, py, px, py + stem)
        gfx.drawLine(px, py + 1, px-2, py + 3)
        gfx.drawLine(px, py + stem-1, px+2, py + stem-3)
    end
end

local function drawTileFace(tile, x, y, w, h, small)
    local suit, number = tileSuit(tile), tileNumber(tile)
    if suit == 1 then drawManMark(number, x, y, w, h, small)
    elseif suit == 2 then drawPinMark(number, x, y, w, h, small)
    else drawSouMark(number, x, y, w, h, small) end
end

local function drawTile(tile, x, y, w, h, small, selectedTile)
    if selectedTile then
        gfx.fillRoundRect(x-2, y-5, w+4, h+7, 4)
    end
    -- Thick lower-right shadow and bright ivory-like face, matching physical tiles.
    gfx.fillRoundRect(x+2, y+3, w, h, 3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, w, h, 3)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, w, h, 3)
    gfx.drawRoundRect(x+1, y+1, w-2, h-2, 2)
    drawTileFace(tile, x, y, w, h, small)
end

local function drawBack(x, y, w, h)
    gfx.fillRoundRect(x+2, y+3, w, h, 3)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(x, y, w, h, 3)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(x, y, w, h, 3)
    gfx.fillRect(x+4, y+4, w-8, h-8)
    gfx.setColor(gfx.kColorWhite)
    for yy=y+6,y+h-6,4 do
        for xx=x+6,x+w-6,4 do gfx.fillRect(xx, yy, 1, 1) end
    end
    gfx.setColor(gfx.kColorBlack)
end

local function drawRiver(river, y, hidden)
    local max = math.min(#river, 18)
    for i=1,max do
        local x = 8 + ((i-1) % 9) * 29
        local row = math.floor((i-1) / 9)
        if hidden and i == #river then drawBack(x, y + row*22, 25, 18)
        else drawTile(river[i], x, y + row*22, 25, 18, true, false) end
    end
end

local function drawGame()
    drawHeader()
    if phase == phases.CPU_RON then
        gfx.fillRect(0, 30, 399, 95)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned("CPU RON!", 200, 38, kTextAlignment.center)
        gfx.drawTextAligned("OPEN HAND", 200, 55, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        for i,tile in ipairs(cpu.hand) do
            drawTile(tile, 23 + (i-1)*25, 76, 21, 27, false, false)
        end
        drawTile(cpuRonTile, 23 + #cpu.hand*25 + 3, 76, 21, 27, false, false)
        gfx.drawTextAligned("RON", 200, 137, kTextAlignment.center)
        gfx.drawText("YOU " .. scores[1] .. "     CPU " .. scores[2], 93, 180)
        return
    end
    gfx.drawText("CPU", 8, 34)
    for i=1,13 do drawBack(48 + (i-1)*25, 31, 20, 25) end
    gfx.drawText("CPU RIVER", 8, 59)
    drawRiver(cpu.river, 75, cpuType == 2 and cpuAbilityUsed)
    gfx.drawLine(0, 113, 399, 113)
    local center = "DRAW TO PLAY"
    if phase == phases.PLAYER then
        center = hintMode and "HINT: KEEP PAIRS / RUNS" or (inspectMode and "INSPECT: RIVERS + PRESSURE" or "CHOOSE A TILE")
        if riichiAutoDiscardAt > nowMs then center = "RIICHI: AUTO DISCARD" end
    end
    if phase == phases.TSUMO then center = "TSUMO?  A: YES   B: NO" end
    if phase == phases.RON then center = "RON?  A: YES   B: NO" end
    if phase == phases.CPU then center = "CPU THINKING..." end
    if phase == phases.ABILITY then center = "ABILITY: A REVERSE  B CLOSE" end
    gfx.drawTextAligned(center, 200, 115, kTextAlignment.center)
    gfx.drawText("YOU RIVER", 8, 135)
    drawRiver(player.river, 150, false)
    local handY = 188
    for i,tile in ipairs(player.hand) do
        drawTile(tile, 7 + (i-1)*28, handY, 25, 30, false, i == selected and phase == phases.PLAYER)
    end
    if phase == phases.PLAYER then gfx.drawText("A CUT   A-HOLD RIICHI   B-HOLD ABILITY", 8, 224)
    elseif phase == phases.TSUMO or phase == phases.RON then gfx.drawText("A YES   B NO", 8, 224)
    else gfx.drawText("A NEXT   B-HOLD REVERSE", 8, 224) end
end

local function drawTitle()
    gfx.fillRect(0,0,399,239)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("TSUKIKAGE", 200, 34, kTextAlignment.center)
    gfx.drawTextAligned("JANTO", 200, 58, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned("1v1 MAHJONG / FOUR HAND MATCH", 200, 89, kTextAlignment.center)
    local items = {"PLAY YUI", "PLAY HAIDO", "HOW TO PLAY"}
    for i,item in ipairs(items) do
        local y = 122 + (i-1)*22
        if menuItem == i then gfx.fillRect(86, y-2, 228, 18); gfx.setImageDrawMode(gfx.kDrawModeFillWhite) end
        gfx.drawTextAligned(item, 200, y, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    gfx.drawTextAligned("UP/DOWN SELECT   A START", 200, 207, kTextAlignment.center)
end

local function drawHelp()
    gfx.drawText("HOW TO PLAY", 12, 8)
    gfx.drawText("A CUT / CONFIRM       B CANCEL", 12, 35)
    gfx.drawText("LEFT/RIGHT  SELECT TILE", 12, 55)
    gfx.drawText("UP  INSPECT RIVERS     DOWN  HINT", 12, 75)
    gfx.drawText("A-HOLD  RIICHI         B-HOLD  ABILITY", 12, 95)
    gfx.drawText("REVERSE rewinds your last draw + cut.", 12, 125)
    gfx.drawText("The next draw changes. RIICHI locks.", 12, 145)
    gfx.drawText("Win with RIICHI, TANYAO, PINFU,", 12, 170)
    gfx.drawText("IIPEIKOU, CHIITOI or CHINITSU.", 12, 188)
    gfx.drawText("A/B: BACK", 12, 222)
end

local function drawResult()
    drawHeader()
    gfx.drawTextAligned(resultText, 200, 42, kTextAlignment.center)
    if resultInfo then
        gfx.drawText("YAKU", 20, 72)
        gfx.drawTextAligned(resultInfo.names, 225, 72, kTextAlignment.center)
        gfx.drawText("WIN", 20, 98)
        drawTile(resultWinTile, 58, 92, 23, 28, false, false)
        gfx.drawText("+" .. resultPoints, 94, 101)
    else
        gfx.drawTextAligned(resultDetail, 200, 92, kTextAlignment.center)
    end
    if resultHand and phase ~= phases.MATCH_RESULT then
        gfx.drawText("CPU HAND", 20, 136)
        for i,tile in ipairs(resultHand) do
            drawTile(tile, 20 + (i-1)*26, 154, 22, 27, false, false)
        end
    end
    gfx.drawText("YOU " .. scores[1] .. "     CPU " .. scores[2], 93, 198)
    if phase == phases.MATCH_RESULT then
        local winner = scores[1] == scores[2] and "SUDDEN DEATH" or (scores[1] > scores[2] and "YOU WIN MATCH" or "CPU WINS MATCH")
        gfx.drawTextAligned(winner, 200, 180, kTextAlignment.center)
        gfx.drawText("A TITLE", 8, 223)
    else gfx.drawText("A NEXT HAND", 8, 223) end
end

local function drawOverlays()
    if phase == phases.ABILITY then
        gfx.fillRect(36, 77, 328, 80)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawText("REVERSE", 52, 88)
        gfx.drawText("rewind last draw + cut", 52, 109)
        gfx.drawText(reverseUsed and "USED" or (reverseReady and "A: USE" or "CUT FIRST"), 52, 132)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    elseif toast ~= "" and nowMs < toastUntil then
        gfx.fillRect(48, 100, 304, 32)
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        gfx.drawTextAligned(toast, 200, 111, kTextAlignment.center)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end
    if nowMs < flashUntil and phase ~= phases.TITLE then
        gfx.drawRect(1,1,397,237)
        gfx.drawRect(3,3,393,233)
    end
end

function pd.update()
    nowMs = pd.getCurrentTimeMilliseconds()
    gfx.clear()
    if phase == phases.TITLE then drawTitle()
    elseif phase == phases.HELP then drawHelp()
    elseif phase == phases.HAND_RESULT or phase == phases.MATCH_RESULT then drawResult()
    else drawGame() end
    drawOverlays()

    if pd.buttonJustPressed(pd.kButtonMenu) then
        if phase == phases.TITLE then phase = phases.HELP
        elseif phase == phases.HELP then phase = phases.TITLE
        elseif phase ~= phases.HAND_RESULT and phase ~= phases.MATCH_RESULT then phase = phases.HELP end
        return
    end

    if pd.buttonJustPressed(pd.kButtonA) then aDownAt = nowMs end
    if pd.buttonJustPressed(pd.kButtonB) then bDownAt = nowMs end
    if pd.buttonJustPressed(pd.kButtonLeft) then
        if phase == phases.TITLE then menuItem = clamp(menuItem - 1, 1, 3)
        elseif phase == phases.PLAYER and riichiAutoDiscardAt == 0 then
            moveHandCursor(-1)
            leftRepeatAt = nowMs + 350
        end
    end
    if pd.buttonJustPressed(pd.kButtonRight) then
        if phase == phases.TITLE then menuItem = clamp(menuItem + 1, 1, 3)
        elseif phase == phases.PLAYER and riichiAutoDiscardAt == 0 then
            moveHandCursor(1)
            rightRepeatAt = nowMs + 350
        end
    end
    if pd.buttonJustPressed(pd.kButtonUp) then
        if phase == phases.TITLE then menuItem = clamp(menuItem - 1, 1, 3)
        elseif phase == phases.PLAYER and riichiAutoDiscardAt == 0 then inspectMode = not inspectMode end
    end
    if pd.buttonJustPressed(pd.kButtonDown) then
        if phase == phases.TITLE then menuItem = clamp(menuItem + 1, 1, 3)
        elseif phase == phases.PLAYER and riichiAutoDiscardAt == 0 then hintMode = not hintMode end
    end

    if pd.buttonJustReleased(pd.kButtonB) then
        local held = nowMs - (bDownAt or nowMs)
        bDownAt = nil
        if held >= 550 and (phase == phases.PLAYER or phase == phases.CPU) then
            phase = phases.ABILITY
        elseif phase == phases.ABILITY then phase = phases.PLAYER
        elseif phase == phases.HELP then phase = phases.TITLE
        elseif phase == phases.TSUMO or phase == phases.RON then
            if phase == phases.TSUMO then phase = phases.PLAYER else beginPlayerDraw() end
        end
    end
    if pd.buttonJustReleased(pd.kButtonLeft) then leftRepeatAt = 0 end
    if pd.buttonJustReleased(pd.kButtonRight) then rightRepeatAt = 0 end
    if pd.buttonJustReleased(pd.kButtonA) then
        local held = nowMs - (aDownAt or nowMs)
        aDownAt = nil
        if phase == phases.TITLE then startSelected()
        elseif phase == phases.HELP then phase = phases.TITLE
        elseif phase == phases.PLAYER and riichiAutoDiscardAt == 0 then playerDiscard(held >= 550 and not reverseUsed)
        elseif phase == phases.TSUMO then
            local info = scoreHand(player.hand, player.riichi)
            finishHand(1, "TSUMO", player.hand[#player.hand], info)
        elseif phase == phases.RON then
            local info = scoreHand(appendTile(player.hand, pendingRonTile), player.riichi)
            finishHand(1, "RON", pendingRonTile, info)
        elseif phase == phases.ABILITY then doReverse()
        elseif phase == phases.HAND_RESULT then advanceHand()
        elseif phase == phases.MATCH_RESULT then phase = phases.TITLE
        end
    end
    if phase == phases.PLAYER and riichiAutoDiscardAt > 0 and nowMs >= riichiAutoDiscardAt then
        selected = #player.hand
        playerDiscard(false)
    end
    if phase == phases.PLAYER and riichiAutoDiscardAt == 0 then
        if pd.buttonIsPressed(pd.kButtonLeft) and leftRepeatAt > 0 and nowMs >= leftRepeatAt then
            moveHandCursor(-1)
            leftRepeatAt = nowMs + 90
        end
        if pd.buttonIsPressed(pd.kButtonRight) and rightRepeatAt > 0 and nowMs >= rightRepeatAt then
            moveHandCursor(1)
            rightRepeatAt = nowMs + 90
        end
    end
    if phase == phases.CPU_RON and nowMs >= cpuRonUntil then
        finishHand(2, "RON", cpuRonTile, cpuRonInfo)
    end
    if phase == phases.CPU and nowMs >= cpuThinkUntil and not pd.buttonIsPressed(pd.kButtonB) then
        cpuTakeTurn()
    end
end

math.randomseed(pd.getSecondsSinceEpoch())
