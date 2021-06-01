##../venn
@implement+=
function M.draw_box()
  @get_box_dimensions
  @get_lines_in_range

  @restore_visual_select
  @get_cursor_position
  @restore_normal

  @append_whitespace_if_outside
  if w == 1 then
    @connect_line_if_possible_vertical
    @draw_vertical_line
  elseif h == 1 then
    @connect_line_if_possible_horizontal
    @draw_horizontal_line
  else
    @draw_over_box_top
    @draw_over_box_bottom
    @draw_over_box_left_right
  end
end

@implement+=
function M.get_width(line, byte)
  if byte then
    local substring = line:sub(1, byte)
    return vim.api.nvim_strwidth(substring)
  else
    return vim.api.nvim_strwidth(line)
  end
end

@get_box_dimensions+=
-- line is 1 indexed, col is 0 indexed 
local _,slnum,sbyte,vscol = unpack(vim.fn.getpos("'<"))
local _,elnum,ebyte,vecol = unpack(vim.fn.getpos("'>"))


@get_lines_in_range+=
local lines = vim.api.nvim_buf_get_lines(0, slnum-1, elnum, true)
local scol = M.get_width(lines[1], sbyte-1) + vscol
local ecol = M.get_width(lines[#lines], ebyte-1) + vecol

local w = ecol - scol + 1
local h = elnum - slnum + 1

@restore_visual_select+=
vim.api.nvim_command [[normal gv]]

@restore_normal+=
vim.api.nvim_command [[normal vv]]

@get_cursor_position+=
local  _,clnum,cbyte,vccol = unpack(vim.fn.getpos('.'))
local ccol = M.get_width(lines[1], cbyte-1) + vccol

@append_whitespace_if_outside+=
for i=1,#lines do
  local len = M.get_width(lines[i])
  local diff = ecol - len + 1
  if diff > 0 then
    @append_whitespaces_at_eol
  end
end

@append_whitespaces_at_eol+=
local extend = ""
for _=1,diff do
  extend = extend .. " "
end
local eol = string.len(lines[i])
vim.api.nvim_buf_set_text(0, slnum-1+(i-1), eol, slnum-1+(i-1), eol, { extend })
lines[i] = lines[i] .. extend

@implement+=
function M.get_bytes(line, col)
  -- kinda slow, not sure how to
  -- make it faster.
  local len = vim.str_utfindex(line)
  for i=0,len do
    local idx = vim.str_byteindex(line, i)
    if vim.api.nvim_strwidth(line:sub(1,idx)) >= col then
      return idx
    end
  end
  return string.len(line)
end

@draw_over_box_top+=
local topborder = ""
for i=scol,ecol do
  if i == scol then
    @draw_upper_left
  elseif i == ecol then
    @draw_upper_right
  else
    @draw_upper_edge
  end
end
local sbyte = M.get_bytes(lines[1], scol)
local ebyte = M.get_bytes(lines[1], ecol+1)
vim.api.nvim_buf_set_text(0, slnum-1, sbyte, slnum-1, ebyte, { topborder })

@script_variables+=
local box_chars = {
	topleft  = '┌', topright = '┐', top      = '─', left     = '│',
	right    = '│', botleft  = '└', botright = '┘', bot      = '─',
  @box_chars
}

@implement+=
function M.set_box_chars(borders)
  box_chars = borders
end

@draw_upper_left+=
topborder = topborder .. box_chars.topleft

@draw_upper_right+=
topborder = topborder .. box_chars.topright

@draw_upper_edge+=
topborder = topborder .. box_chars.top

@draw_over_box_bottom+=
local botborder = ""
for i=scol,ecol do
  if i == scol then
    @draw_lower_left
  elseif i == ecol then
    @draw_lower_right
  else
    @draw_lower_edge
  end
end

local sbyte = M.get_bytes(lines[#lines], scol)
local ebyte = M.get_bytes(lines[#lines], ecol+1)
vim.api.nvim_buf_set_text(0, elnum-1, sbyte, elnum-1, ebyte, { botborder })

@draw_lower_left+=
botborder = botborder .. box_chars.botleft

@draw_lower_right+=
botborder = botborder .. box_chars.botright

@draw_lower_edge+=
botborder = botborder .. box_chars.bot

@draw_over_box_left_right+=
for i=slnum,elnum-2 do
  @draw_left_border
  @draw_right_border
end

@draw_left_border+=
local len = string.len(lines[i-slnum+2])
local sbyte = M.get_bytes(lines[i-slnum+2], scol)
local sbyte_end = M.get_bytes(lines[i-slnum+2], scol+1)
vim.api.nvim_buf_set_text(0, i, sbyte, i, sbyte_end, { box_chars.left })
lines[i-slnum+2] = vim.api.nvim_buf_get_lines(0, i, i+1, true)[1]

@scratch+=

    col
  0 |1 |2 3
   a| b| c
  1 |2 |3 4
    lua 

@draw_right_border+=
local ebyte = M.get_bytes(lines[i-slnum+2], ecol)
local ebyte_end = M.get_bytes(lines[i-slnum+2], ecol+1)
vim.api.nvim_buf_set_text(0, i, ebyte, i, ebyte_end, { box_chars.right })

@script_variables+=
local line_chars = {
  vert = '│',
  hori = '─',
  @line_chars
}

local arrow_chars = {
  up = '▲', down = '▼', left = '◄', right = '►',
}

@implement+=
function M.set_line_chars(chars)
  line_chars = chars
end

function M.set_arrow_chars(chars)
  arrow_chars = chars
end

@draw_vertical_line+=
for i=slnum-1,elnum-1 do
  local sbyte = M.get_bytes(lines[i-slnum+2], scol)
  local sbyte_end = M.get_bytes(lines[i-slnum+2], scol+1)

  local c
  if i+1 == clnum then
    @determine_arrow_up_or_down
  elseif i == elnum-1 or i == slnum-1 then
    c = start or line_chars.vert
  else
    c = line_chars.vert
  end
  vim.api.nvim_buf_set_text(0, i, sbyte, i, sbyte_end , { c })
end

@determine_arrow_up_or_down+=
if i == slnum-1 then
  c = arrow_chars.up
else
  c = arrow_chars.down
end

@draw_horizontal_line+=
local line = ''
for i=scol,ecol do
  local c 
  if i == ccol then
    @determine_if_arrow_left_or_right
  elseif i == scol or i == ecol then
    c = start or line_chars.hori
  else
    c = line_chars.hori
  end
  line = line .. c
end

local sbyte = M.get_bytes(lines[1], scol)
local ebyte = M.get_bytes(lines[1], ecol+1)
vim.api.nvim_buf_set_text(0, slnum-1, sbyte, slnum-1, ebyte, { line })

@determine_if_arrow_left_or_right+=
if i == scol then
  c = arrow_chars.left
else
  c = arrow_chars.right
end

@connect_line_if_possible_vertical+=
local start
if clnum == elnum then
  local sbyte = M.get_bytes(lines[1], scol)
  local ebyte = M.get_bytes(lines[1], scol+1)

  c = lines[1]:sub(sbyte+1, ebyte)

  @connect_line_going_down
else
  local sbyte = M.get_bytes(lines[#lines], ecol)
  local ebyte = M.get_bytes(lines[#lines], ecol+1)

  c = lines[#lines]:sub(sbyte+1, ebyte)

  @connect_line_going_up
end

@connect_line_going_down+=
if c == arrow_chars.left then
  start = line_chars.topleft
elseif c == arrow_chars.right then
  start = line_chars.topright
elseif c == line_chars.botleft then
  start = line_chars.vertright
elseif c == line_chars.botright then 
  start = line_chars.vertleft
elseif c == line_chars.horiup then 
  start = line_chars.cross
elseif c == line_chars.hori then
  start = line_chars.horidown
end

@connect_line_going_up+=
if c == arrow_chars.left then
  start = line_chars.botleft
elseif c == arrow_chars.right then
  start = line_chars.botright
elseif c == line_chars.topright then
  start = line_chars.vertleft
elseif c == line_chars.topleft then
  start = line_chars.vertright
elseif c == line_chars.horidown then
  start = line_chars.cross
elseif c == line_chars.hori then
  start = line_chars.horiup
end

@connect_line_if_possible_horizontal+=
local start
if ccol == ecol then
  local sbyte = M.get_bytes(lines[1], scol)
  local ebyte = M.get_bytes(lines[1], scol+1)

  c = lines[1]:sub(sbyte+1, ebyte)

  @connect_line_going_right
else
  local sbyte = M.get_bytes(lines[1], ecol)
  local ebyte = M.get_bytes(lines[1], ecol+1)

  c = lines[#lines]:sub(sbyte+1, ebyte)

  @connect_line_going_left
end

@line_chars+=
horidown = '┬',
vertleft = '┤',
cross = '┼',
horiup = '┴',
topleft  = '┌', 
topright = '┐', 
botleft  = '└', 
botright = '┘',

@connect_line_going_right+=
if c == arrow_chars.up then
  start = line_chars.topleft
elseif c == arrow_chars.down then
  start = line_chars.botleft
elseif c == line_chars.topright then
  start = line_chars.horidown
elseif c == line_chars.vertleft then
  start = line_chars.cross
elseif c == line_chars.botright then
  start = line_chars.horiup
elseif c == line_chars.vert then
  start = line_chars.vertright
end

@line_chars+=
vertright = '├',

@connect_line_going_left+=
if c == arrow_chars.up then
  start = line_chars.topright
elseif c == arrow_chars.down then
  start = line_chars.botright
elseif c == line_chars.topleft then
  start = line_chars.horidown
elseif c == line_chars.vertright then
  start = line_chars.cross
elseif c == line_chars.botleft then
  start = line_chars.horiup
elseif c == line_chars.vert then
  start = line_chars.vertleft
end