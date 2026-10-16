local M = {}
local mode = "noctalia"

local function mix(a, b, amount)
  local result = {}
  for offset = 2, 6, 2 do
    local x = tonumber(a:sub(offset, offset + 1), 16)
    local y = tonumber(b:sub(offset, offset + 1), 16)
    result[#result + 1] = string.format("%02x", math.floor(x * (1 - amount) + y * amount + 0.5))
  end
  return "#" .. table.concat(result)
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
    keyword = c.base08
    string = mix(c.base09, c.base08, 0.35)
    number = mix(c.base08, c.base0A, 0.45)
    func = c.base0B
    method = mix(c.base0B, c.base0C, 0.35)
    type_color = c.base0C
    property = mix(c.base09, c.base0B, 0.45)
    parameter = mix(c.base0B, c.base05, 0.5)
    constant = mix(c.base08, c.base09, 0.5)
    variable = mix(c.base05, c.base0A, 0.25)
    operator = c.base04
    punctuation = c.base03
    comment = c.base03
  end
  local control_flow = mode == "classic" and "#f36b9a" or keyword
  local builtin_type = mode == "classic" and "#23b9e7" or type_color

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
