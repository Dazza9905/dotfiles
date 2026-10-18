local M = {}
local mode = "noctalia"
local saturation_boost = 2.5
local hue_spread = 0.73

local function saturate(color, target_lightness)
  local channels = {}
  for offset = 2, 6, 2 do
    channels[#channels + 1] = tonumber(color:sub(offset, offset + 1), 16) / 255
  end
  local low, high = math.min(unpack(channels)), math.max(unpack(channels))
  local chroma = high - low
  if chroma == 0 then
    return color
  end

  -- Scale HSL saturation without clipping. Lower accent lightness on dark
  -- backgrounds to avoid fully saturated colors still looking pastel.
  local lightness = (high + low) / 2
  local gamut = 1 - math.abs(2 * lightness - 1)
  local output_lightness = target_lightness or lightness
  local scale = math.min(saturation_boost, gamut / chroma)
    * (1 - math.abs(2 * output_lightness - 1)) / gamut
  for i, channel in ipairs(channels) do
    channels[i] = string.format("%02x", math.floor((output_lightness + (channel - lightness) * scale) * 255 + 0.5))
  end
  return "#" .. table.concat(channels)
end

local function mix(a, b, amount)
  local result = {}
  for offset = 2, 6, 2 do
    local x = tonumber(a:sub(offset, offset + 1), 16)
    local y = tonumber(b:sub(offset, offset + 1), 16)
    result[#result + 1] = string.format("%02x", math.floor(x * (1 - amount) + y * amount + 0.5))
  end
  return "#" .. table.concat(result)
end

local function rotate_hue(color, degrees)
  local r, g, b = tonumber(color:sub(2, 3), 16) / 255, tonumber(color:sub(4, 5), 16) / 255,
    tonumber(color:sub(6, 7), 16) / 255
  local low, high = math.min(r, g, b), math.max(r, g, b)
  local chroma = high - low
  if chroma == 0 then
    return color
  end
  local hue
  if high == r then
    hue = ((g - b) / chroma) % 6
  elseif high == g then
    hue = (b - r) / chroma + 2
  else
    hue = (r - g) / chroma + 4
  end
  hue = (hue + degrees * hue_spread / 60) % 6
  local x = chroma * (1 - math.abs(hue % 2 - 1))
  local sectors = { { chroma, x, 0 }, { x, chroma, 0 }, { 0, chroma, x },
    { 0, x, chroma }, { x, 0, chroma }, { chroma, 0, x } }
  local channels = sectors[math.floor(hue) + 1]
  return string.format("#%02x%02x%02x", math.floor((channels[1] + low) * 255 + 0.5),
    math.floor((channels[2] + low) * 255 + 0.5), math.floor((channels[3] + low) * 255 + 0.5))
end

function M.apply(c)
  -- Noctalia changes with the wallpaper; classic keeps syntax colors fixed.
  local keyword, string, number, func, method, type_color
  local property, parameter, constant, variable, operator, punctuation, comment
  if mode == "classic" then
    keyword = "#c678dd"
    string = "#56c96b"
    number = "#23b9e7"
    func = "#bb86e8"
    method = "#bb86e8"
    type_color = "#bb86e8"
    property = "#e7a900"
    parameter = "#e7a900"
    constant = "#e7a900"
    variable = "#dedede"
    operator = "#24bce5"
    punctuation = "#888888"
    comment = "#777777"
  else
    -- Anchor role hues to the generated function accent. Fixed offsets keep
    -- roles distinct even when the wallpaper produces near-identical accents.
    local background = tonumber(c.base00:sub(2, 3), 16) + tonumber(c.base00:sub(4, 5), 16)
      + tonumber(c.base00:sub(6, 7), 16)
    local accent = saturate(c.base0B, background < 384 and 0.77 or 0.38)
    keyword = rotate_hue(accent, 30)
    string = rotate_hue(accent, -140)
    number = rotate_hue(accent, -90)
    func = accent
    method = rotate_hue(accent, -15)
    type_color = rotate_hue(accent, 60)
    property = rotate_hue(accent, 125)
    parameter = property
    constant = property
    variable = mix(c.base05, c.base0A, 0.25)
    operator = number
    punctuation = c.base03
    comment = c.base03
  end
  local control_flow = mode == "classic" and "#f36b9a" or type_color
  local builtin_type = mode == "classic" and "#23b9e7" or number

  local groups = {
    ["@keyword"] = { fg = keyword, bold = true },
    ["@keyword.function"] = { fg = keyword, bold = true },
    ["@keyword.import"] = { fg = keyword },
    ["@keyword.operator"] = { fg = control_flow },
    ["@keyword.conditional"] = { fg = control_flow },
    ["@keyword.return"] = { fg = control_flow },
    ["@keyword.exception"] = { fg = control_flow },
    ["@conditional"] = { fg = control_flow, bold = true },
    ["@repeat"] = { fg = control_flow, bold = true },
    ["@string"] = { fg = string },
    ["@string.escape"] = { fg = keyword },
    ["@character"] = { fg = string },
    ["@number"] = { fg = number },
    ["@boolean"] = { fg = constant, bold = true },
    ["@constant"] = { fg = constant },
    ["@constant.builtin"] = { fg = constant, bold = true },
    ["@function"] = { fg = func },
    ["@function.call"] = { fg = func },
    ["@function.builtin"] = { fg = func, bold = true },
    ["@function.method"] = { fg = method },
    ["@function.method.call"] = { fg = method },
    ["@method"] = { fg = method },
    ["@method.call"] = { fg = method },
    ["@type"] = { fg = type_color, bold = true },
    ["@type.builtin"] = { fg = builtin_type },
    ["@constructor"] = { fg = type_color },
    ["@attribute"] = { fg = property },
    ["@property"] = { fg = property },
    ["@variable"] = { fg = variable },
    ["@variable.parameter"] = { fg = parameter, italic = true },
    ["@parameter"] = { fg = parameter, italic = true },
    ["@variable.builtin"] = { fg = constant },
    ["@operator"] = { fg = operator },
    ["@punctuation.delimiter"] = { fg = punctuation },
    ["@punctuation.bracket"] = { fg = punctuation },
    ["@comment"] = { fg = comment, italic = true },
    ["@tag"] = { fg = keyword },
    ["@tag.attribute"] = { fg = property },
    ["@markup.heading"] = { fg = type_color, bold = true },
    ["@markup.link"] = { fg = func, underline = true },
    ["@markup.raw"] = { fg = string },
    -- Semantic tokens from ty and other language servers use the same roles.
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.variable"] = { link = "@variable" },
    ["@lsp.type.property"] = { link = "@property" },
    ["@lsp.type.function"] = { link = "@function" },
    ["@lsp.type.method"] = { link = "@function.method" },
    ["@lsp.type.class"] = { link = "@type" },
    ["@lsp.type.enum"] = { link = "@type" },
    ["@lsp.type.interface"] = { link = "@type" },
    ["@lsp.type.struct"] = { link = "@type" },
    ["@lsp.type.enumMember"] = { link = "@constant" },
    ["@lsp.type.decorator"] = { link = "@attribute" },
    ["@lsp.type.builtinType"] = { link = "@type.builtin" },
    ["@lsp.type.selfParameter"] = { link = "@variable.parameter" },
    ["@lsp.type.typeParameter"] = { link = "@type" },
    -- Vim syntax remains readable in files without a Tree-sitter parser.
    Keyword = { fg = keyword, bold = true },
    Statement = { fg = keyword },
    String = { fg = string },
    Number = { fg = number },
    Function = { fg = func },
    Type = { fg = type_color, bold = true },
    Identifier = { fg = variable },
    Constant = { fg = constant },
    Conditional = { fg = control_flow },
    Repeat = { fg = control_flow },
    Operator = { fg = operator },
  }

  for group, opts in pairs(groups) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

function M.toggle()
  mode = mode == "noctalia" and "classic" or "noctalia"
  require("matugen").setup()
  vim.notify("Syntax palette: " .. mode)
end

function M.mode()
  return mode
end

return M
