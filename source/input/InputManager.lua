import "CoreLibs/object"

InputManager = class("InputManager").extends() or InputManager

local bindings = {
    A = playdate.kButtonA,
    B = playdate.kButtonB,
    LEFT = playdate.kButtonLeft,
    RIGHT = playdate.kButtonRight,
    UP = playdate.kButtonUp,
    DOWN = playdate.kButtonDown,
}

function InputManager:init()
    self.downAt = {}
    self.events = {}
end

function InputManager:update(now)
    self.events = {}
    for name, button in pairs(bindings) do
        if playdate.buttonJustPressed(button) then
            self.downAt[name] = now
            self.events[name] = { pressed = true }
        end
        if playdate.buttonJustReleased(button) then
            local held = now - (self.downAt[name] or now)
            self.events[name] = { released = true, held = held, long = held >= 550 }
            self.downAt[name] = nil
        end
    end
end

function InputManager:pressed(name)
    return self.events[name] and self.events[name].pressed == true
end

function InputManager:released(name)
    return self.events[name] and self.events[name].released == true
end

function InputManager:event(name)
    return self.events[name]
end

return InputManager
