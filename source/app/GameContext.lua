import "CoreLibs/object"

import "scenes/TitleScene"
import "scenes/HelpScene"
import "scenes/HandScene"
import "scenes/ResultScene"

---@class GameContext ゲーム全体で共有するオブジェクトを保持するコンテキスト.
---@field game Game ゲーム本体.
---@field input InputManager 入力管理.
---@field sceneManager SceneManager シーン管理.
---@field match Match? 現在の対戦. 対戦開始前はnil.
GameContext = class("GameContext").extends() or GameContext

---初期化.
---@param game Game ゲーム本体.
---@param input InputManager 入力管理.
---@param sceneManager SceneManager シーン管理.
function GameContext:init(game, input, sceneManager)
    self.game = game
    self.input = input
    self.sceneManager = sceneManager
    self.match = nil
end

---対戦開始.
---@param cpuType CPU_TYPE CPUの種類.
function GameContext:startMatch(cpuType)
    self.game:startMatch(cpuType)
end

---タイトルシーンを生成.
---@return TitleScene
function GameContext:titleScene()
    return TitleScene(self)
end

---ヘルプシーンを生成.
---@return HelpScene
function GameContext:helpScene()
    return HelpScene(self)
end

---手牌シーンを生成.
---@return HandScene
function GameContext:handScene()
    return HandScene(self)
end

---結果シーンを生成.
---@return ResultScene
function GameContext:resultScene()
    return ResultScene(self)
end

return GameContext
