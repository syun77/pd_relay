---@enum CPU_TYPE CPUの種類.
local CpuType = {
	YUI = 1,
	HAIDO = 2,
}

---@enum PLAYER_ID プレイヤーID.
local PlayerID = {
	HUMAN = 1,
	CPU = 2,
	DRAW = 0,
}

---@enum Suit 牌のスーツ.
local Suit = {
    MAN = 1,   -- 萬子.
    PIN = 2,   -- 筒子.
    SOU = 3,   -- 索子.
    HONOR = 4, -- 字牌.
}

---@enum Honor 字牌の種類.
local Honor = {
    EAST = 1,         -- 東.
    SOUTH = 2,        -- 南.
    WEST = 3,         -- 西.
    NORTH = 4,        -- 北.
    WHITE_DRAGON = 5, -- 白.
    GREEN_DRAGON = 6, -- 發.
    RED_DRAGON = 7,   -- 中.
}

Constants = {
    Game = {
        CPU_TYPE = CpuType,
		CPU_TYPE_FIRST = CpuType.YUI, -- 開始.
		CPU_TYPE_LAST = CpuType.HAIDO, -- 終端.

        SUIT = Suit,
        SUIT_NAME = {
            [Suit.MAN] = "M",
            [Suit.PIN] = "P",
            [Suit.SOU] = "S",
            [Suit.HONOR] = "Z",
        },
        SUIT_NAME_LONG = {
            [Suit.MAN] = "MAN",
            [Suit.PIN] = "PIN",
            [Suit.SOU] = "SOU",
            [Suit.HONOR] = "HONOR",
        },
        HONOR = Honor,
        HONOR_NAME = {
            [Honor.EAST] = "E",
            [Honor.SOUTH] = "S",
            [Honor.WEST] = "W",
            [Honor.NORTH] = "N",
            [Honor.WHITE_DRAGON] = "P",
            [Honor.GREEN_DRAGON] = "F",
            [Honor.RED_DRAGON] = "C",
        },

        PLAYER_ID = PlayerID,
		
        PLAYER_NAME = {
            HUMAN = "YOU",
            CPU = "CPU",
        },
        INITIAL_SCORE = 25000,
        HANDS_PER_MATCH = 4,
        TILE = {
            MIN_INDEX = 0,
            NUMBERED_MAX_INDEX = 26,
            HONOR_MIN_INDEX = 27,
            HONOR_MAX_INDEX = 33,
            MAX_INDEX = 33,
            PLAYABLE_MAX_INDEX = 26,
            COPIES_PER_TYPE = 4,
            TYPES_PER_SUIT = 9,
            NUMBERED_SUIT_COUNT = 3,
            SUIT_COUNT = 4,
        },
        HAND = {
            STARTING_TILES = 13,
            COMPLETE_TILES = 14,
        },
        WALL = {
            DEAL_END_POSITION = 26,
            PLAYABLE_TILES = 50,
        },
        SCORE = {
            MIN_POINTS = 1000,
            MAX_POINTS = 8000,
            BASE_POINTS = 1000,
        },
        PRESSURE = {
            MIN = 0,
            MAX = 5,
            VALUE_PER_LEVEL = 4,
            ABILITY_BONUS = 1,
        },
    },
    UI = {
		-- 解像度.
        SCREEN = {
            WIDTH = 400,
            HEIGHT = 240,
            CENTER_X = 200,
        },
        INPUT = {
            LONG_PRESS_MS = 550, -- 長押し判定 (msec).
        },
        TIMING = {
            CPU_TURN_DELAY_MS = 350,
            RIICHI_DRAW_DELAY_MS = 500,
            ERROR_TOAST_MS = 1100,
            ABILITY_TOAST_MS = 1200,
        },

		-- 牌の描画サイズ.
        TILE_SIZE = {
            LARGE = { -- 大きい牌.
                WIDTH = 25,
                HEIGHT = 30,
            },
            SMALL = { -- 小さい牌.
                WIDTH = 25,
                HEIGHT = 18,
            },
            BACK = { -- 裏面.
                WIDTH = 20,
                HEIGHT = 25,
            },
            RESULT_WIN = { -- リザルト画面の牌.
                WIDTH = 23,
                HEIGHT = 28,
            },
            RESULT_HAND = { -- リザルト画面の手牌.
                WIDTH = 22,
                HEIGHT = 27,
            },
            SMALL_DRAW_MAX_WIDTH = 25, -- 大きいと判定するしきい値.
        },
        TITLE = {
            FIRST_ITEM = 1,
            LAST_ITEM = 3,
            HELP_ITEM = 3,
            ITEM_TOP = 122,
            ITEM_GAP = 22,
        },
        HAND = {
            CPU_TILE_COUNT = 13,
            CPU_TILE_START_X = 48,
            CPU_TILE_GAP = 25,
            PLAYER_TILE_START_X = 7,
            PLAYER_TILE_GAP = 28,
            RIVER_START_X = 8,
            RIVER_COLUMNS = 9,
            RIVER_MAX_TILES = 18,
            RIVER_TILE_GAP_X = 29,
            RIVER_ROW_GAP = 22,
        },
    },
}

return Constants
