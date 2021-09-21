local hsluv = require("nightfox.hsluv")

local util = {}

util.bg = "#000000"
util.fg = "#ffffff"
util.day_brightness = 0.3

function util.warn(...)
  for _, msg in ipairs({ ... }) do
    vim.api.nvim_command('echohl WarningMsg | echom "Nightfox: ' .. msg .. '" | echohl NONE')
  end
end

function util.hex_to_rgb(hex_str)
  local hex = "[abcdef0-9][abcdef0-9]"
  local pat = "^#(" .. hex .. ")(" .. hex .. ")(" .. hex .. ")$"
  hex_str = string.lower(hex_str)

  assert(string.find(hex_str, pat) ~= nil, "hex_to_rgb: invalid hex_str: " .. tostring(hex_str))

  local r, g, b = string.match(hex_str, pat)
  return { tonumber(r, 16), tonumber(g, 16), tonumber(b, 16) }
end

function util.hex_to_norm_rgb(hex_str)
  local c = util.hex_to_rgb(hex_str)
  return { c[1] / 255, c[2] / 255, c[3] / 255 }
end

---@param fg string foreground color
---@param bg string background color
---@param alpha number number between 0 and 1. 0 results in bg, 1 results in fg
function util.blend(fg, bg, alpha)
  bg = util.hex_to_rgb(bg)
  fg = util.hex_to_rgb(fg)

  local blendChannel = function(i)
    local ret = (alpha * fg[i] + ((1 - alpha) * bg[i]))
    return math.floor(math.min(math.max(0, ret), 255) + 0.5)
  end

  return string.format("#%02X%02X%02X", blendChannel(1), blendChannel(2), blendChannel(3))
end

function util.darken(hex, amount, bg)
  return util.blend(hex, bg or util.bg, math.abs(amount))
end

function util.lighten(hex, amount, fg)
  return util.blend(hex, fg or util.fg, math.abs(amount))
end

function util.brighten(color, percentage)
  local hsl = hsluv.hex_to_hsluv(color)
  local larpSpace = 100 - hsl[3]
  if percentage < 0 then
    larpSpace = hsl[3]
  end
  hsl[3] = hsl[3] + larpSpace * percentage
  return hsluv.hsluv_to_hex(hsl)
end

function util.invertColor(color)
  if color ~= "NONE" then
    local hsl = hsluv.hex_to_hsluv(color)
    hsl[3] = 100 - hsl[3]
    if hsl[3] < 40 then
      hsl[3] = hsl[3] + (100 - hsl[3]) * util.day_brightness
    end
    return hsluv.hsluv_to_hex(hsl)
  end
  return color
end

function util.color_overrides(colors, config)
  if type(config.colors) == "table" then
    for key, value in pairs(config.colors) do
      if not colors[key] then
        error("Color " .. key .. " does not exist")
      end

      -- Patch: https://github.com/ful1e5/onedark.nvim/issues/6
      if type(colors[key]) == "table" then
        util.color_overrides(colors[key], { colors = value })
      else
        if value:lower() == "none" then
          -- set to none
          colors[key] = "NONE"
        elseif string.sub(value, 1, 1) == "#" then
          -- hex override
          colors[key] = value
        else
          -- another group
          if not colors[value] then
            error("Color " .. value .. " does not exist")
          end
          colors[key] = colors[value]
        end
      end
    end
  end
end

function util.string_to_color(colors, value, default)
  if not value or value == "" then
    return default
  end

  -- If the value is a hex color code then return it
  local hex = "[abcdef0-9][abcdef0-9]"
  local pat = "^#" .. hex .. hex .. hex .. "$"
  if string.match(value, pat) then
    return value
  end

  local acceptable_colors = { "black", "red", "green", "blue", "magenta", "cyan", "white", "orange", "pink" }
  for _, ac in ipairs(acceptable_colors) do
    if string.match(value, ac) then
      return colors[value]
    end
  end

  -- Did not match anything to return default
  return default
end

function util.highlight(group, color)
  local style = color.style and "gui=" .. color.style or "gui=NONE"
  local fg = color.fg and "guifg=" .. color.fg or "guifg=NONE"
  local bg = color.bg and "guibg=" .. color.bg or "guibg=NONE"
  local sp = color.sp and "guisp=" .. color.sp or ""
  local hl = "highlight " .. group .. " " .. style .. " " .. fg .. " " .. bg .. " " .. sp

  vim.cmd(hl)
  if color.link then
    vim.cmd("highlight! link " .. group .. " " .. color.link)
  end
end

-- Simple string interpolation.
--
-- Example template: "${name} is ${value}"
--
---@param str string template string
---@param tbl table key value pairs to replace in the string
function util.template(str, tbl)
  local function parse(split, t)
    local name = table.remove(split, 1)
    local result = t[name]
    if not result then
      return nil
    end

    return type(result) == "table" and parse(split, result) or result
  end
  return (
      str:gsub("($%b{})", function(w)
        local name = w:sub(3, -2)
        local split = vim.split(name, ".", true)
        return parse(split, tbl) or w
      end)
    )
end

-- Template values in a table recursivly
---@param table table the table to be replaced
---@param values table the values to be replaced by the template strings in the table passed in
function util.template_table(table, values)
  -- if the value passed is a string the return templated resolved string
  if type(table) == "string" then
    return util.template(table, values)
  end

  -- If the table passed in is a table then iterate though the children and call template table
  for key, value in pairs(table) do
    table[key] = util.template_table(value, values)
  end

  return table
end

function util.syntax(tbl)
  for group, colors in pairs(tbl) do
    util.highlight(group, colors)
  end
end

function util.terminal(theme)
  vim.g.terminal_color_0 = theme.colors.black
  vim.g.terminal_color_1 = theme.colors.red
  vim.g.terminal_color_2 = theme.colors.green
  vim.g.terminal_color_3 = theme.colors.yellow
  vim.g.terminal_color_4 = theme.colors.blue
  vim.g.terminal_color_5 = theme.colors.magenta
  vim.g.terminal_color_6 = theme.colors.cyan
  vim.g.terminal_color_7 = theme.colors.white

  vim.g.terminal_color_8 = theme.colors.black_br
  vim.g.terminal_color_9 = theme.colors.red_br
  vim.g.terminal_color_10 = theme.colors.green_br
  vim.g.terminal_color_11 = theme.colors.yellow_br
  vim.g.terminal_color_12 = theme.colors.blue_br
  vim.g.terminal_color_13 = theme.colors.magenta_br
  vim.g.terminal_color_14 = theme.colors.cyan_br
  vim.g.terminal_color_15 = theme.colors.white_br
end

function util.load(theme, exec_autocmd)
  -- only needed to clear when not the default colorscheme
  if vim.g.colors_name then
    vim.cmd("hi clear")
  end

  vim.o.background = theme.colors.light and "light" or "dark"
  vim.o.termguicolors = true
  vim.g.colors_name = theme.name

  local hlgroups = util.template_table(theme.config.hlgroups, theme.colors)
  local groups = vim.tbl_deep_extend("force", theme.groups, hlgroups)

  util.syntax(groups)

  if theme.config.terminal_colors then
    util.terminal(theme)
  end

  if exec_autocmd then
    vim.cmd([[doautocmd ColorScheme]])
  end
end

return util
