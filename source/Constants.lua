---@enum CPU_TYPE CPUの種類.
local CpuType = {
	YUI = 1,
	HAIDO = 2,
}

Constants = {
    Game = {
        CPU_TYPE = CpuType,
		CPU_TYPE_FIRST = CpuType.YUI, -- 開始.
		CPU_TYPE_LAST = CpuType.HAIDO, -- 終端.
		
        PLAYER_ID = {
            HUMAN = 1,
            CPU = 2,
            DRAW = 0,
        },
        PLAYER_NAME = {
            HUMAN = "YOU",
            CPU = "CPU",
        },
        INITIAL_SCORE = 25000,
        HANDS_PER_MATCH = 4,
        TILE = {
            MIN_INDEX = 0,
            MAX_INDEX = 26,
            COPIES_PER_TYPE = 4,
            TYPES_PER_SUIT = 9,
            SUIT_COUNT = 3,
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
        SCREEN = {
            WIDTH = 400,
            HEIGHT = 240,
            CENTER_X = 200,
        },
        INPUT = {
            LONG_PRESS_MS = 550,
        },
        TIMING = {
            CPU_TURN_DELAY_MS = 350,
            RIICHI_DRAW_DELAY_MS = 500,
            ERROR_TOAST_MS = 1100,
            ABILITY_TOAST_MS = 1200,
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
