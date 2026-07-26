--[[
========================================================
	手牌描画モジュール.
========================================================
]]
import "Constants"
import "domain/Tile"

local gfx <const> = playdate.graphics

---@class TileRenderer 牌の描画を行うモジュール.
TileRenderer = {}

---筒子の点の配置.
local pipLayouts = {
    [1]={{2,2}},
	[2]={{1,1},{3,3}},
	[3]={{1,1},{2,2},{3,3}},
    [4]={{1,1},{3,1},{1,3},{3,3}},
	[5]={{1,1},{3,1},{2,2},{1,3},{3,3}},
    [6]={{1,1},{3,1},{1,2},{3,2},{1,3},{3,3}},
    [7]={{1,1},{3,1},{2,2},{1,3},{3,3},{1,4},{3,4}},
    [8]={{1,1},{3,1},{1,2},{3,2},{1,3},{3,3},{1,4},{3,4}},
    [9]={{1,1},{2,1},{3,1},{1,2},{2,2},{3,2},{1,3},{2,3},{3,3}}
}

---萬子の描画.
---@param number number 萬子の数値.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
---@param small boolean 小さいサイズで描画するかどうか.
local function drawMan(number, x, y, w, h, small)
    local cx, top = x + math.floor(w / 2), y + (small and 9 or 13)
    local span, foot = small and 4 or 6, small and 8 or 10
    gfx.drawTextAligned(tostring(number), cx, y + (small and 0 or 1), kTextAlignment.center)
    gfx.drawLine(cx-span, top, cx+span, top);
	gfx.drawLine(cx, top-2, cx, top+7)
    gfx.drawLine(cx-span+1, top+3, cx+span-1, top+3);
	gfx.drawLine(cx-span, top+7, cx+span, top+7)
    gfx.drawLine(cx-span+2, top+7, cx-span+2, top+foot);
	gfx.drawLine(cx+span-2, top+7, cx+span-2, top+foot)
end

---筒子の描画.
---@param number number 筒子の数値.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
---@param small boolean 小さいサイズで描画するかどうか.
local function drawPin(number, x, y, w, h, small)
    local points = pipLayouts[number]
    local rows = (number >= 7 and number <= 8) and 4 or 3
    local left, right = x + (small and 5 or 6), x + w - (small and 5 or 6)
    local top, bottom = y + (small and 4 or 5), y + h - (small and 4 or 5)
    local radius = small and 1 or 2
    for _, point in ipairs(points) do
        local px = left + math.floor((point[1] - 1) * (right - left) / 2)
        local py = top + math.floor((point[2] - 1) * (bottom - top) / math.max(1, rows - 1))
        gfx.fillCircleAtPoint(px, py, radius)
        if not small and radius > 1 then
            gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(px, py, 1); gfx.setColor(gfx.kColorBlack)
        end
    end
end

---索子の描画.
---@param number number 索子の数値.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
---@param small boolean 小さいサイズで描画するかどうか.
local function drawSou(number, x, y, w, h, small)
    local cols = number <= 3 and number or 3
    local rows = math.ceil(number / cols)
    local left, right = x + 6, x + w - 6
    local top, bottom = y + (small and 3 or 4), y + h - (small and 3 or 4)
    for i = 1, number do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local px = cols == 1 and math.floor((left + right) / 2) or left + math.floor(col * (right - left) / (cols - 1))
        local py = rows == 1 and top + 1 or top + math.floor(row * (bottom - top - 5) / math.max(1, rows - 1))
        local stem = small and 4 or 6
        gfx.drawLine(px, py, px, py + stem); gfx.drawLine(px, py + 1, px - 2, py + 3)
        gfx.drawLine(px, py + stem - 1, px + 2, py + stem - 3)
    end
end

---字牌の描画.
---@param number number 字牌の種類.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
local function drawHonor(number, x, y, w, h)
    local text = Constants.Game.HONOR_NAME[number] or "?"
    gfx.drawTextAligned(
        text,
        x + math.floor(w / 2),
        y + math.floor((h - 12) / 2),
        kTextAlignment.center
    )
end

---描画.
---@param tile number 牌の種類.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
---@param small boolean 小さいサイズで描画するかどうか.
---@param selected boolean 選択されているかどうか.
function TileRenderer.draw(tile, x, y, w, h, small, selected)
    if selected then
		-- 選択枠の描画.
		gfx.fillRoundRect(x - 2, y - 5, w + 4, h + 7, 4)
	end

	-- 牌の枠の描画.
    gfx.fillRoundRect(x + 2, y + 3, w, h, 3);
	gfx.setColor(gfx.kColorWhite);
	gfx.fillRoundRect(x, y, w, h, 3)
    gfx.setColor(gfx.kColorBlack);
	gfx.drawRoundRect(x, y, w, h, 3);
	gfx.drawRoundRect(x + 1, y + 1, w - 2, h - 2, 2)

    local suit, number = Tile.suit(tile), Tile.number(tile)
    if suit == Constants.Game.SUIT.MAN then
		-- 萬子の描画.
		drawMan(number, x, y, w, h, small)
    elseif suit == Constants.Game.SUIT.PIN then
		-- 筒子の描画.
		drawPin(number, x, y, w, h, small)
    elseif suit == Constants.Game.SUIT.SOU then
		-- 索子の描画.
		drawSou(number, x, y, w, h, small)
    else
        -- 字牌の描画.
        drawHonor(number, x, y, w, h)
	end
end

---牌の裏側の描画.
---@param x number 描画位置X.
---@param y number 描画位置Y.
---@param w number 幅.
---@param h number 高さ.
function TileRenderer.drawBack(x, y, w, h)
    gfx.fillRoundRect(x + 2, y + 3, w, h, 3);
	gfx.setColor(gfx.kColorWhite);
	gfx.fillRoundRect(x, y, w, h, 3)
    gfx.setColor(gfx.kColorBlack);
	gfx.drawRoundRect(x, y, w, h, 3);
	gfx.fillRect(x + 4, y + 4, w - 8, h - 8)
    gfx.setColor(gfx.kColorWhite)
    for yy = y + 6, y + h - 6, 4 do
		for xx = x + 6, x + w - 6, 4 do
			gfx.fillRect(xx, yy, 1, 1)
		end
	end
    gfx.setColor(gfx.kColorBlack)
end

return TileRenderer
