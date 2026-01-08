local M = {}

function M.setup()

  local colors = {
    bg = "#1e1e2e",
    fg = "#b4befe",
    red = "#df4576",
    green = "#00ffd2",
    blue = "#004687",
    yellow = "#f9e2af",
    purple = "#cba6f7",
    cyan = "#89dceb",
    gray = "#9399b2",
  }

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
