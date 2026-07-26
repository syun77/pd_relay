import "CoreLibs/object"
import "Constants"
import "domain/Hand"

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
