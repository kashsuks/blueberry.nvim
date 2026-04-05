local M = {}

M.config = {
  -- theme can be: "dark", "light", or "auto"
  -- "auto" follows vim.o.background ("dark"/"light")
  theme = "auto", -- can be "dark" or "light" by default
  -- transparent can be: true, false, or "auto",
  -- "auto" tries to respect an already-transparent UI (winblend/pumblend or Normal bg = NONE)
  transparent = true,
  telescope_translucent = true,
}

local palettes = {
  dark = {
    bg = "#232639",
    fg = "#b4befe",
    red = "#df4576",
    green = "#00ffd2",
    blue = "#C19CEE",
    yellow = "#f9e2af",
    purple = "#cba6f7",
    cyan = "#89dceb",
    gray = "#9399b2",
  },
  light = {
    bg = "#eff1f5",
    fg = "#4c4f69",
    red = "#d20f39",
    green = "#40a02b",
    blue = "#1e66f5",
    yellow = "#df8e1d",
    purple = "#8839ef",
    cyan = "#179299",
    gray = "#7c7f93",
  }
}

local function clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end

local function hex_to_rgb(hex)
  if type(hex) ~= "string" then
    return nil
  end

  hex = hex:gsub("#", "")
  if #hex ~= 6 then
    return nil
  end

  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  if r == nil or g == nil or b == nil then
    return nil
  end
  return r, g, b
end

local function rgb_to_hex(r, g, b)
  r = math.max(0, math.min(255, math.floor(r + 0.5)))
  g = math.max(0, math.min(255, math.floor(g + 0.5)))
  b = math.max(0, math.min(255, math.floor(b + 0.5)))
  return string.format("#%02x%02x%02x", r, g, b)
end

local function blend(fg_hex, bg_hex, alpha)
  alpha = clamp01(alpha or 0.5)

  local fg_r, fg_g, fg_b = hex_to_rgb(fg_hex)
  local bg_r, bg_g, bg_b = hex_to_rgb(bg_hex)

  if fg_r == nil or bg_r == nil then
    return fg_hex
  end

  local out_r = (alpha * fg_r) + ((1 - alpha) * bg_r)
  local out_g = (alpha * fg_g) + ((1 - alpha) * bg_g)
  local out_b = (alpha * fg_b) + ((1 - alpha) * bg_b)

  return rgb_to_hex(out_r, out_g, out_b)
end

local function get_hl(name)
  -- Neovim 0.9+: nvim_get_hl
  if vim.api.nvim_get_hl then
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok then return hl end
  end

  -- older version fallback: nvim_get_hl_by_name (return decimal colors)
  if vim.api.nvim_get_hl_by_name() then
    local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
    if ok then return hl end
  end

  return {}
end

local function resolve_theme(theme_opt)
  if theme_opt == "auto" then
    return (vim.o.background == "light") and "light" or "dark"
  end
  return (theme_opt == "light") and "light" or "dark"
end

local function resolve_transparent(transparent_opt)
  if transparent_opt == "auto" then
    -- if the user is already using blended floats/menus then transparency is usually wanted
    if (vim.o.winblend and vim.o.winblend > 0) or (vim.o.pumblend and vim.o.pumblend > 0) then
      return true
    end 

    -- if the current normal background is none, treat that as transparent
    local normal = get_hl("Normal")
    if normal and normal.bg == nil then
      return true
    end


    return false
  end
  return transparent_opt and true or false
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- core boilerplate for reloads
  vim.o.termguicolors = true
  vim.cmd("highlight clear")
  vim.g.colors_name = "blueberry"

  local theme = resolve_theme(M.config.theme)
  local colors = palettes[theme] or palettes.dark

  vim.o.background = theme

  local is_transparent = resolve_transparent(M.config.transparent)
  local bg = M.config.transparent and "NONE" or colors.bg
  local status_bg = blend(colors.fg, colors.bg, 0.06)
  local status_nc_bg = blend(colors.gray, colors.bg, 0.04)

  local function st_mode(color)
    return { fg = colors.bg, bg = color, bold = true }
  end

  local function st_mode_sep(color)
    return { fg = color, bg = status_bg }
  end

  M.state = {
    theme = theme,
    colors = colors,
    is_transparent = is_transparent,
    bg = bg,
  }

  local function telescope_title(color)
    if is_transparent then
      return { fg = color, bg = "NONE", bold = true}
    end
      return { fg = colors.bg, bg = color, bold = true}
  end

  local telescope_glass = M.config.telescope_translucent
  local glass_bg = telescope_glass and "NONE" or bg
  local glass_border = telescope_glass and colors.gray or colors.blue
  local glass_fg = telescope_glass and colors.fg or colors.fg

  if telescope_glass then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "TelescopeResults,TelescopePrompt,TelescopePreview",
      callback = function()
        vim.wo.winblend = 15
      end,
      once = true,
    })
  end

  -- highlight groups
  local highlights = {
    Normal = { fg = colors.fg, bg = bg },
    NormalFloat = { fg = colors.fg, bg = bg},
    SignColumn = { bg = bg },
    Comment = { fg = colors.gray, italic = true },
    Keyword = { fg = colors.purple, bold = true },
    String = { fg = colors.green },
    Number = { fg = colors.yellow },
    LineNr = { fg = colors.gray, bg = bg },
    CursorLine = is_transparent and { underline = true } or { bg = bg },
    StatusLine = { fg = colors.fg, bg = status_bg },
    StatusLineNC = { fg = colors.gray, bg = status_nc_bg },
    Visual = is_transparent and { underline = true, bold = true }
     or { bg = colors.blue, fg = colors.bg },

    -- NvChad statusline groups
    St_NormalMode = st_mode(colors.purple),
    St_InsertMode = st_mode(colors.green),
    St_VisualMode = st_mode(colors.cyan),
    St_ReplaceMode = st_mode(colors.red),
    St_CommandMode = st_mode(colors.yellow),
    St_TerminalMode = st_mode(colors.blue),
    St_NTerminalMode = st_mode(colors.blue),
    St_ConfirmMode = st_mode(colors.yellow),
    St_SelectMode = st_mode(colors.cyan),

    St_NormalModeSep = st_mode_sep(colors.purple),
    St_InsertModeSep = st_mode_sep(colors.green),
    St_VisualModeSep = st_mode_sep(colors.cyan),
    St_ReplaceModeSep = st_mode_sep(colors.red),
    St_CommandModeSep = st_mode_sep(colors.yellow),
    St_TerminalModeSep = st_mode_sep(colors.blue),
    St_NTerminalModeSep = st_mode_sep(colors.blue),
    St_ConfirmModeSep = st_mode_sep(colors.yellow),
    St_SelectModeSep = st_mode_sep(colors.cyan),

    St_EmptySpace = { fg = colors.fg, bg = status_bg },
    St_EmptySpace2 = { fg = colors.fg, bg = status_bg },
    St_Cwd = { fg = colors.fg, bg = status_bg },
    St_CwdSep = { fg = status_bg, bg = status_bg },
    St_Lsp = { fg = colors.fg, bg = status_bg },
    St_LspSep = { fg = status_bg, bg = status_bg },
    St_Progress = { fg = colors.fg, bg = status_bg },
    St_ProgressSep = { fg = status_bg, bg = status_bg },
    St_Position = { fg = colors.fg, bg = status_bg },
    St_PositionSep = { fg = status_bg, bg = status_bg },
    St_StFile = { fg = colors.fg, bg = status_bg },
    St_StFileSep = { fg = status_bg, bg = status_bg },
    St_Icon = { fg = colors.fg, bg = status_bg },

    -- tree sitter
    ["@variable"] = { fg = colors.blue },
    ["@keyword"] = { fg = colors.purple, bold = true },

    -- telescope 
    TelescopeNormal = { fg = glass_fg, bg = glass_bg },
    TelescopeBorder = { fg = glass_border, bg = glass_bg, sp = glass_border },
    TelescopeTitle = telescope_title(colors.blue),

    TelescopePromptNormal = { fg = glass_fg, bg = glass_bg },
    TelescopePromptBorder = { fg = glass_border, bg = glass_bg, sp = glass_border },
    TelescopePromptTitle = telescope_title(colors.purple),
    TelescopePromptPrefix = { fg = colors.purple, bg = glass_bg, bold = true },

    TelescopeResultsNormal = { fg = glass_fg, bg = glass_bg },
    TelescopeResultsBorder = { fg = glass_border, bg = glass_bg, sp = glass_border },
    TelescopeResultsTitle = telescope_title(colors.green),

    TelescopePreviewNormal = { fg = glass_fg, bg = glass_bg },
    TelescopePreviewBorder = { fg = glass_border, bg = glass_bg, sp = glass_border },
    TelescopePreviewTitle = telescope_title(colors.cyan),

    TelescopeMatching = { fg = colors.yellow, bold = true },

    TelescopeSelection = telescope_glass
      and { fg = colors.fg, bg = "NONE", underline = true, bold = true}
      or (is_transparent and { fg = colors.fg, bg = "NONE", underline = true, bold = true}
      or { fg = colors.fg, bg = colors.blue}),
    TelescopeSelectionCaret = telescope_glass
      and { fg = glass_border, bg = "NONE", bold = true }
      or (is_transparent and { fg = colors.blue, bg = "NONE", bold = true }
      or { fg = colors.bg, bg = colors.blue, bold = true }),

    TelescopeMultiSelection = { fg = colors.yellow, bold = true },
    TelescopeMultiIcon = { fg = colors.yellow },
    TelescopeResultsComment = { fg = colors.gray, italic = true },
  }

  -- apply highlights
  for group, hl_opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, hl_opts)
  end

  pcall(function()
    require("blueberry.zen").apply_if_active(M.state)
  end)
end

-- light and dark theme toggle
function M.toggle()
  local theme = resolve_theme(M.config.theme)
  M.config.theme = (theme == "dark") and "light" or "dark"
  M.setup(M.config)
end

function M.load()
  M.setup(M.config)
end

vim.api.nvim_create_user_command("BlueberryToggle", function()
  require("blueberry").toggle()
end, {})

vim.api.nvim_create_user_command("Zen", function()
  local bb = require("blueberry")
  if not bb.state then
    bb.setup(bb.config)
  end
  require("blueberry.zen").toggle(bb.state)
end, {})

return M
