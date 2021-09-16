local util = require("nightfox.util")

local M = {}

-- Return the initial colors of the colorscheme. This is the default defined colors
-- without the color overrides from the configuration.
function M.init()
  -- References:
  -- https://coolors.co/ffa69e-faf3dd-b8f2e6-aed9e0-5e6472
  -- https://coolors.co/555b6e-89b0ae-bee3db-faf9f9-ffd6ba
  -- https://coolors.co/9c89b8-f0a6ca-efc3e6-f0e6ef-b8bedd
  -- https://coolors.co/8da1b9-95adb6-cbb3bf-dbc7be-ef959c

  -- stylua: ignore
  colors = {
    name = "pastelfox",

    none       = "NONE",
    bg         = "#363A46",

    fg         = "#F0F0F0",
    fg_gutter  = "#5E6472",

    blue       = "#a2d2ff",
    black      = "#393b44",
    cyan       = "#B8F2E6",
    green      = "#8DBA9D",
    magenta    = "#9A83C3",
    orange     = "#DC9256",
    pink       = "#D67AD2",
    red        = "#C68080",
    yellow     = "#DBC7BE",
    white      = "#dfdfe0",

    blue_br    = "#84CEE4",
    black_br   = "#7f8c98",
    cyan_br    = "#59F0FF",
    green_br   = "#58cd8b",
    magenta_br = "#B8A1E3",
    orange_br  = "#E2A573",
    pink_br    = "#DF97DB",
    red_br     = "#D6616B",
    yellow_br  = "#FFE37E",
    white_br   = "#F2F2F2",

    comment    = "#788091",

    git = {
      add      = "#70a288",
      change   = "#A58155",
      delete   = "#904A6A",
      conflict = "#C07A6D",
    },
    gitSigns = {
      add      = "#164846",
      change   = "#394b70",
      delete   = "#823c41",
    },
  }

  util.bg = colors.bg

  colors.bg_alt = util.darken(colors.bg, 0.75, "#000000")
  colors.bg_highlight = util.brighten(colors.bg, 0.10)

  colors.fg_alt = util.darken(colors.fg, 0.80, "#000000")

  colors.diff = {
    add = util.darken(colors.green, 0.15),
    delete = util.darken(colors.red, 0.15),
    change = util.darken(colors.blue, 0.15),
    text = colors.blue,
  }

  colors.gitSigns = {
    add = util.brighten(colors.gitSigns.add, 0.2),
    change = util.brighten(colors.gitSigns.change, 0.2),
    delete = util.brighten(colors.gitSigns.delete, 0.2),
  }

  colors.git.ignore = colors.black
  colors.black = util.darken(colors.bg, 0.8, "#000000")
  colors.border_highlight = colors.blue
  colors.border = colors.black

  -- Popups and statusline always get a dark background
  colors.bg_popup = colors.bg_alt
  colors.bg_statusline = colors.bg_alt

  colors.bg_sidebar = colors.bg_alt
  colors.bg_float = colors.bg_alt

  colors.bg_visual = util.darken(colors.blue, 0.2)
  colors.bg_search = util.darken(colors.cyan, 0.3)
  colors.fg_sidebar = colors.fg_alt

  colors.error = colors.red
  colors.warning = colors.yellow
  colors.info = colors.blue
  colors.hint = colors.cyan

  colors.variable = colors.white

  return colors
end

-- Returns the completed colors with the overrides from the configuration
-- @param config table
function M.load(config)
  config = config or require("nightfox.config").options

  local colors = M.init()
  util.color_overrides(colors, config)

  return colors
end

return M
