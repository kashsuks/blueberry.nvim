local M = {}

M.config = {
  -- theme can be: "dark", "light", or "auto"
  -- "auto" follows vim.o.background ("dark"/"light")
  theme = "auto", -- can be "dark" or "light" by default
  -- transparent can be: true, false, or "auto",
  -- "auto" tries to respect an already-transparent UI (winblend/pumblend or Normal bg = NONE)
  transparent = "auto",
}

local palettes = {
  dark = {
    bg = "#1e1e2e",
    fg = "#b4befe",
    red = "#df4576",
    green = "#00ffd2",
    blue = "#00a9ff",
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
    StatusLine = { fg = colors.fg, bg = colors.blue },
    Visual = is_transparent and { underline = true, bold = true }
     or { bg = colors.blue, fg = colors.bg },

    -- tree sitter
    ["@variable"] = { fg = colors.blue },
    ["@keyword"] = { fg = colors.purple, bold = true },

    -- telescope 
    TelescopeNormal = { fg = colors.fg, bg = bg},
    TelescopeBorder = { fg = colors.blue, bg = bg},
    TelescopeTitle = telescope_title(colors.blue),

    TelescopePromptNormal = { fg = colors.fg, bg = bg},
    TelescopePromptBorder = { fg = colors.blue, bg = bg},
    TelescopePromptTitle = telescope_title(colors.purple),
    TelescopePromptPrefix = { fg = colors.purple, bg = bg, bold = true },

    TelescopeResultsNormal = { fg = colors.fg, bg = bg},
    TelescopeResultsBorder = { fg = colors.blue, bg = bg},
    TelescopeResultsTitle = telescope_title(colors.green),

    TelescopePreviewNormal = { fg = colors.fg, bg = bg },
    TelescopePreviewBorder = { fg = colors.blue, bg = bg },
    TelescopePreviewTitle = telescope_title(colors.cyan),

    TelescopeMatching = { fg = colors.yellow, bold = true },

    -- when in transparent mode, avoid a big filled selction block
    TelescopeSelection = is_transparent
      and { fg = colors.fg, bg = "NONE", underline = true, bold = true}
      or { fg = colors.fg, bg = colors.blue},
    TelescopeSelectionCaret = is_transparent
      and { fg = colors.blue, bg = "NONE", bold = true }
      or { fg = colors.bg, bg = colors.blue, bold = true },

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
