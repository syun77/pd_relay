import "CoreLibs/object"
import "Constants"
import "domain/Hand"

---@class Player プレイヤーの状態を保持するオブジェクト.
---@field id number プレイヤーID.
---@field name string プレイヤー名.
---@field hand Hand 手牌.
---@field score number スコア.
Player = class("Player").extends() or Player

function Player:init(id, name)
    self.id = id
    self.name = name
    self.hand = Hand()
    self.score = Constants.Game.INITIAL_SCORE
end

function Player:resetHand()
    self.hand:reset()
end

return Player
