import "CoreLibs/object"

import "Constants"
import "domain/Tile"
import "domain/Hand"
import "domain/Player"
import "domain/Wall"
import "domain/MahjongRules"
import "domain/ScoreCalculator"
import "domain/CpuStrategy"

---@class Match 対戦の状態を保持するオブジェクト.
Match = class("Match").extends() or Match

local function shuffle(deck)
    for i = #deck, 2, -1 do
        local j = math.random(i)
        deck[i], deck[j] = deck[j], deck[i]
    end
end

local function makeWall()
    local deck = {}
    for tile = Constants.Game.TILE.MIN_INDEX, Constants.Game.TILE.MAX_INDEX do
        for _ = 1, Constants.Game.TILE.COPIES_PER_TYPE do table.insert(deck, tile) end
    end
    shuffle(deck)
    return deck
end

function Match:init(cpuType)
    self.cpuType = cpuType or Constants.Game.CPU_TYPE.YUI
    self.handNumber = 1
    self.dealer = Constants.Game.PLAYER_ID.HUMAN
    self.players = {
        Player(Constants.Game.PLAYER_ID.HUMAN, Constants.Game.PLAYER_NAME.HUMAN),
        Player(Constants.Game.PLAYER_ID.CPU, Constants.Game.PLAYER_NAME.CPU),
    }
    self.wall = nil
    self.pressure = 0
    self.targetSuit = nil
    self.cpuAbilityUsed = false
    self.reverseUsed = false
    self.reverseReady = false
    self.reverseSnapshot = nil
    self.lastResult = nil
end

function Match:player()
    return self.players[Constants.Game.PLAYER_ID.HUMAN]
end

function Match:cpu()
    return self.players[Constants.Game.PLAYER_ID.CPU]
end

function Match:score(playerId)
    return self.players[playerId].score
end

function Match:resetScores()
    self.players[Constants.Game.PLAYER_ID.HUMAN].score = Constants.Game.INITIAL_SCORE
    self.players[Constants.Game.PLAYER_ID.CPU].score = Constants.Game.INITIAL_SCORE
end

function Match:startHand()
    self.wall = Wall(makeWall())
    self.wall.position = Constants.Game.WALL.DEAL_END_POSITION
    self.wall.endPosition = math.min(
        #self.wall.tiles,
        self.wall.position + Constants.Game.WALL.PLAYABLE_TILES
    )
    self.wall.doraIndicator = self.wall.tiles[self.wall.endPosition + 1] or self.wall.tiles[1]

    self:player():resetHand()
    self:cpu():resetHand()
    local player, cpu = self:player(), self:cpu()
    for _ = 1, Constants.Game.HAND.STARTING_TILES do
        self.wall:draw()
        player.hand:add(self.wall.tiles[self.wall.position])
    end
    for _ = 1, Constants.Game.HAND.STARTING_TILES do
        self.wall:draw()
        cpu.hand:add(self.wall.tiles[self.wall.position])
    end

    self.pressure = 0
    self.targetSuit = nil
    self.cpuAbilityUsed = false
    self.reverseUsed = false
    self.reverseReady = false
    self.reverseSnapshot = nil
    self.lastResult = nil
    self:updatePressure()
end

function Match:drawForPlayer()
    local player = self:player()
    if self.wall:remaining() <= 0 then
        return nil, { winner = Constants.Game.PLAYER_ID.DRAW, winType = "DRAW", points = 0 }
    end

    self.reverseSnapshot = {
        hand = Hand(),
        wall = self.wall:copy()
    }
    self.reverseSnapshot.hand.tiles = Tile.copyArray(player.hand.tiles)
    self.reverseSnapshot.hand.river = Tile.copyArray(player.hand.river)
    self.reverseSnapshot.hand.riichi = player.hand.riichi
    self.reverseReady = false

    local tile = self.wall:draw()
    player.hand:add(tile, false)
    local info = ScoreCalculator.calculate(player.hand.tiles, player.hand.riichi, self.wall.doraIndicator)
    self:updatePressure()
    return tile, info
end

function Match:playerCanRiichi(index)
    return not self.reverseUsed and not self:player().hand.riichi
        and Rules.canRiichiAfterDiscard(self:player().hand.tiles, index)
end

function Match:playerDiscard(index, riichi)
    local player, cpu = self:player(), self:cpu()
    if #player.hand.tiles ~= Constants.Game.HAND.COMPLETE_TILES then return nil, "INVALID_HAND" end
    if riichi and not self:playerCanRiichi(index) then return nil, "RIICHI_NOT_AVAILABLE" end

    local discard = player.hand:discardAt(index)
    if riichi then player.hand.riichi = true end
    local ronInfo = ScoreCalculator.calculate(
        Rules.appendTile(cpu.hand.tiles, discard), cpu.hand.riichi, self.wall.doraIndicator
    )
    if ronInfo then
        return discard, { type = "CPU_RON", tile = discard, info = ronInfo }
    end

    self.reverseReady = true
    return discard, { type = "CPU_TURN" }
end

function Match:useReverse()
    if self.reverseUsed then return false, "REVERSE_USED" end
    if not self.reverseReady or not self.reverseSnapshot then return false, "CUT_FIRST" end

    local player = self:player()
    player.hand = self.reverseSnapshot.hand:copy()
    self.wall = self.reverseSnapshot.wall:copy()
    self.reverseUsed = true
    self.reverseReady = false
    player.hand.riichi = false
    self.targetSuit = nil
    return true
end

function Match:cpuTurn()
    local player, cpu = self:player(), self:cpu()
    if self.cpuType == Constants.Game.CPU_TYPE.HAIDO and not self.cpuAbilityUsed then
        self.cpuAbilityUsed = true
        self.targetSuit = math.random(1, Constants.Game.TILE.SUIT_COUNT)
        for i = self.wall.position + 1, self.wall.endPosition do
            if Tile.suit(self.wall.tiles[i]) == self.targetSuit then
                self.wall.tiles[self.wall.position + 1], self.wall.tiles[i] = self.wall.tiles[i], self.wall.tiles[self.wall.position + 1]
                break
            end
        end
    end

    local tile = self.wall:draw()
    if not tile then return { type = "DRAW" } end
    cpu.hand:add(tile)
    local info = ScoreCalculator.calculate(cpu.hand.tiles, cpu.hand.riichi, self.wall.doraIndicator)
    if info then return { type = "CPU_TSUMO", tile = tile, info = info } end

    local discard = cpu.hand:discardAt(CpuStrategy.discardIndex(cpu.hand.tiles, self.targetSuit))
    self:updatePressure()
    local ronInfo = ScoreCalculator.calculate(
        Rules.appendTile(player.hand.tiles, discard), player.hand.riichi, self.wall.doraIndicator
    )
    if ronInfo and not Rules.containsTile(player.hand.river, discard) then
        return { type = "RON", tile = discard, info = ronInfo }
    end
    return { type = "PLAYER_DRAW" }
end

function Match:finishHand(winner, winType, winTile, info)
    local points = 0
    if info then
        points = math.min(
            Constants.Game.SCORE.MAX_POINTS,
            math.max(
                Constants.Game.SCORE.MIN_POINTS,
                Constants.Game.SCORE.BASE_POINTS * (2 ^ math.max(0, info.han - 1))
            )
        )
    end
    if winner == Constants.Game.PLAYER_ID.HUMAN then
        self:player().score = self:player().score + points
        self:cpu().score = self:cpu().score - points
    elseif winner == Constants.Game.PLAYER_ID.CPU then
        self:player().score = self:player().score - points
        self:cpu().score = self:cpu().score + points
    end
    self.lastResult = {
        winner = winner,
        winType = winType,
        winTile = winTile,
        info = info,
        points = points,
        cpuHand = Tile.copyArray(self:cpu().hand.tiles)
    }
    return self.lastResult
end

function Match:advanceHand()
    local result = self.lastResult
    if self.handNumber >= Constants.Game.HANDS_PER_MATCH then return false end
    if result and result.winner ~= Constants.Game.PLAYER_ID.DRAW and result.winner == self.dealer then
        self.dealer = Constants.Game.PLAYER_ID.HUMAN + Constants.Game.PLAYER_ID.CPU - self.dealer
    end
    self.handNumber = self.handNumber + 1
    self:startHand()
    return true
end

function Match:updatePressure()
    local cpu = self:cpu()
    local counts = Rules.countsFor(cpu.hand.tiles)
    local value = 0
    for i = Constants.Game.TILE.MIN_INDEX, Constants.Game.TILE.MAX_INDEX do
        if counts[i] >= 2 then value = value + 1 end
        if counts[i] >= 3 then value = value + 1 end
        local number = Tile.number(i)
        if number <= 7 and counts[i] > 0 and counts[i + 1] > 0 then value = value + 1 end
        if number <= 6 and counts[i] > 0 and counts[i + 2] > 0 then value = value + 1 end
    end
    if self.targetSuit then
        for _, tile in ipairs(cpu.hand.tiles) do
            if Tile.suit(tile) == self.targetSuit then value = value + 1 end
        end
    end
    self.pressure = math.min(
        Constants.Game.PRESSURE.MAX,
        math.max(
            Constants.Game.PRESSURE.MIN,
            math.floor(value / Constants.Game.PRESSURE.VALUE_PER_LEVEL)
                + (self.cpuAbilityUsed and Constants.Game.PRESSURE.ABILITY_BONUS or 0)
        )
    )
end

return Match
