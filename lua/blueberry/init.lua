local M = {}

M.config = {
  theme = "dark" -- can be "dark" or "light" by default
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

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local colors = palettes[M.config.theme] or palettes.dark

  vim.o.background = M.config.theme

  -- highlight groups
  local highlights = {
    Normal = { fg = colors.fg, bg = colors.bg },
    Comment = { fg = colors.gray, italic = true },
    Keyword = { fg = colors.purple, bold = true },
    String = { fg = colors.green },
    Number = { fg = colors.yellow },
    LineNr = { fg = colors.gray },
    CursorLine = { bg = colors.bg },
    StatusLine = { fg = colors.fg, bg = colors.blue },
    Visual = { bg = colors.blue, fg = colors.bg },

    -- tree sitter
    ["@variable"] = { fg = colors.blue },
    ["@keyword"] = { fg = colors.blue },
  }

  -- apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
