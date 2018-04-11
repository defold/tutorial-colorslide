local M = {}

-- board tile colors
M.TILE_BLANK = 1
M.TILE_GREY = 2
M.TILE_RED = 3
M.TILE_YELLOW = 4
M.TILE_GREEN = 5
M.TILE_BLUE = 6

-- brick colors
M.GREY = 8
M.RED = 9
M.YELLOW = 10
M.GREEN = 11
M.BLUE = 12

-- compare colors. bricks and board colors are from different
-- parts of the tileset so they cannot be directly compared.
M.compare = function(brick_color, board_color)
	return brick_color - 6 == board_color
end

return M