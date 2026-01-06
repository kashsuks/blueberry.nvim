local M = {}

function M.setup()

  local colors = {
    bg = "#89b4fa",
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
  }

  -- apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end

end

return M
