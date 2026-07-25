import "CoreLibs/object"
import "domain/Hand"

Player = class("Player").extends() or Player

function Player:init(id, name)
    self.id = id
    self.name = name
    self.hand = Hand()
    self.score = 25000
end

function Player:resetHand()
    self.hand:reset()
end

return Player
