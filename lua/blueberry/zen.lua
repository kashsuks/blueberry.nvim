local Z = {}

Z.active = false
Z._saved_hl = {}
Z._saved_opts = nil

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
  if vim.api.nvim_get_hl then
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok then return hl end
  end
  if vim.api.nvim_get_hl_by_name then
    local ok, hl = pcall(vim.api.nvim_get_hl_by_name, name, true)
    if ok then return hl end
  end
  return {}
end

local function save_hl_once(name)
  if Z._saved_hl[name] ~= nil then return end
  Z._saved_hl[name] = get_hl(name)
end

local function set_hl(name, val)
  vim.api.nvim_set_hl(0, name, val)
end

local function apply_zen(state)
  local colors = state.colors
  local base_bg = colors.bg -- use palette bg for blending
  local transparent = state.is_transparent

  if not Z._saved_opts then
    Z._saved_opts = {
      cursorline = vim.o.cursorline,
    }
  end
  vim.o.cursorline = true

  save_hl_once("LineNr")
  set_hl("LineNr", {
    fg = blend(colors.gray, base_bg, 0.55),
    bg = transparent and "NONE" or base_bg,
  })

  save_hl_once("Comment")
  set_hl("Comment", { fg = blend(colors.gray, base_bg, 0.45), italic = true })

  save_hl_once("CursorLine")
  if transparent then
    set_hl("CursorLine", { underline = true, bold = true })
  else
    set_hl("CursorLine", { bg = blend(colors.blue, base_bg, 0.12) })
  end

  local diag = {
    { "Error", colors.red },
    { "Warn", colors.yellow },
    { "Info", colors.blue },
    { "Hint", colors.cyan },
  }

  for _, item in ipairs(diag) do
    local kind, col = item[1], item[2]

    local group_main = "Diagnostic" .. kind
    save_hl_once(group_main)
    set_hl(group_main, { fg = blend(col, base_bg, 0.70) })

    local group_vt = "DiagnosticVirtualText" .. kind
    save_hl_once(group_vt)
    set_hl(group_vt, {
      fg = blend(col, base_bg, 0.55),
      bg = transparent and "NONE" or blend(col, base_bg, 0.08),
    })

    local group_ul = "DiagnosticUnderline" .. kind
    save_hl_once(group_ul)
    set_hl(group_ul, { sp = blend(col, base_bg, 0.65), underline = true })
  end
end

local function restore()
  if Z._saved_opts then
    vim.o.cursorline = Z._saved_opts.cursorline
  end
  Z._saved_opts = nil

  for name, hl in pairs(Z._saved_hl) do
    vim.api.nvim_set_hl(0, name, hl or {})
  end
  Z._saved_hl = {}
end

function Z.toggle(state)
  if Z.active then
    restore()
    Z.active = false
    return
  end

  apply_zen(state)
  Z.active = true
end

function Z.apply_if_active(state)
  if not Z.active then return end
  apply_zen(state)
end

return Z