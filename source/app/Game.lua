--[[

]]
-- SDK.
import "CoreLibs/object"
-- App.
import "domain/Match"
import "input/InputManager"
import "app/SceneManager"
import "app/GameContext"

---@class Game ゲームのメインクラス.
---@field input InputManager 入力管理.
---@field sceneManager SceneManager シーン管理.
---@field match Match? 対戦の状態を保持するオブジェクト.
---@field context GameContext 各種オブジェクトを保持するコンテキスト.
Game = class("Game").extends() or Game

-- 初期化.
function Game:init()
	-- 入力管理.
    self.input = InputManager()
	-- シーン管理.
    self.sceneManager = SceneManager()
    self.match = nil
	-- 各種オブジェクトを保持するコンテキスト.
    self.context = GameContext(self, self.input, self.sceneManager)

	-- タイトルシーンに遷移.
    self.sceneManager:change(self.context:titleScene())
end

---対戦開始.
---@param cpuType CPU_TYPE CPUの種類.
function Game:startMatch(cpuType)
    self.match = Match(cpuType)
    self.context.match = self.match
    self.match:startHand()
    self.sceneManager:change(self.context:handScene())
end

---更新.
function Game:update()
    local now = playdate.getCurrentTimeMilliseconds()
    self.input:update(now)
    self.sceneManager:update(self.input, now)
end

---描画.
function Game:draw()
    playdate.graphics.clear()
    self.sceneManager:draw()
end

return Game
