import "CoreLibs/object"

---@class Scene シーンの基底クラス.
---@field context GameContext 各種オブジェクトを保持するコンテキスト.
Scene = class("Scene").extends() or Scene

---初期化.
---@param context GameContext 各種オブジェクトを保持するコンテキスト.
function Scene:init(context)
    self.context = context
end

---開始.
function Scene:enter()
end

function Scene:leave()
end

---更新.
function Scene:update(input, now)
end

---描画.
function Scene:draw()
end

return Scene
