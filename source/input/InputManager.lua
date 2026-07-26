import "CoreLibs/object"
import "Constants"

---@class InputManager 入力管理クラス.
---@field downAt table<string, number> ボタンが押された時刻を保持するテーブル.
---@field events table<string, table> ボタンの押下・離上イベントを保持するテーブル.
---@field bindings table<string, number> ボタンのバインディングを保持するテーブル.
---@field pressed fun(self: InputManager, name: string): boolean 指定されたボタンが押されたかどうかを返す関数.
---@field released fun(self: InputManager, name: string): boolean 指定されたボタンが離上されたかどうかを返す関数.
---@field event fun(self: InputManager, name: string): table 指定されたボタンのイベント情報を返す関数.
InputManager = class("InputManager").extends() or InputManager

local bindings = {
    A = playdate.kButtonA,
    B = playdate.kButtonB,
    LEFT = playdate.kButtonLeft,
    RIGHT = playdate.kButtonRight,
    UP = playdate.kButtonUp,
    DOWN = playdate.kButtonDown,
}

---初期化.
function InputManager:init()
    self.downAt = {}
    self.events = {}
    self.bindings = bindings
end

---更新.
function InputManager:update(now)
    self.events = {}
    for name, button in pairs(bindings) do
        if playdate.buttonJustPressed(button) then
            self.downAt[name] = now
            self.events[name] = { pressed = true }
        end
        if playdate.buttonJustReleased(button) then
            local held = now - (self.downAt[name] or now)
            self.events[name] = {
                released = true,
                held = held,
                long = held >= Constants.UI.INPUT.LONG_PRESS_MS,
            }
            self.downAt[name] = nil
        end
    end
end

---指定されたボタンが押されたかどうかを返す.
---@param name string ボタン名.
---@return boolean
function InputManager:pressed(name)
    return self.events[name] and self.events[name].pressed == true
end

---指定されたボタンが離されたかどうかを返す.
---@param name string ボタン名.
---@return boolean
function InputManager:released(name)
    return self.events[name] and self.events[name].released == true
end

---指定されたボタンのイベント情報を返す.
---@param name string ボタン名.
---@return table
function InputManager:event(name)
    return self.events[name]
end

return InputManager
