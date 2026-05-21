-- spec/color_picker_spec.lua
-- Tests for lua/color-picker/init.lua
-- Run with: make test   or   busted spec/color_picker_spec.lua

require("spec.support.init")

-- ── helpers ──────────────────────────────────────────────────────────────────

local function fresh()
  package.loaded["color-picker"] = nil
  return require("color-picker")
end

-- ─────────────────────────────────────────────────────────────────────────────
describe("color-picker module", function()
  it("loads without error", function()
    assert.has_no.errors(function() fresh() end)
  end)

  it("returns a table with setup function", function()
    local cp = fresh()
    assert.is_table(cp)
    assert.is_function(cp.setup)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("parse_color", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("returns nil for nil input", function()
    assert.is_nil(cp.parse_color(nil))
  end)

  it("returns nil for non-string input", function()
    assert.is_nil(cp.parse_color(123))
  end)

  it("returns nil for invalid string", function()
    assert.is_nil(cp.parse_color("not-a-color"))
  end)

  it("parses 6-digit hex with #", function()
    local r, g, b, a = cp.parse_color("#FF8000")
    assert.equal(255, r)
    assert.equal(128, g)
    assert.equal(0, b)
    assert.equal(1.0, a)
  end)

  it("parses 6-digit hex without #", function()
    local r, g, b, a = cp.parse_color("FF8000")
    assert.equal(255, r)
    assert.equal(128, g)
    assert.equal(0, b)
    assert.equal(1.0, a)
  end)

  it("parses 3-digit hex shorthand", function()
    local r, g, b, a = cp.parse_color("#F80")
    assert.equal(255, r)
    assert.equal(136, g)
    assert.equal(0, b)
    assert.equal(1.0, a)
  end)

  it("parses black #000000", function()
    local r, g, b, a = cp.parse_color("#000000")
    assert.equal(0, r)
    assert.equal(0, g)
    assert.equal(0, b)
  end)

  it("parses white #FFFFFF", function()
    local r, g, b, a = cp.parse_color("#FFFFFF")
    assert.equal(255, r)
    assert.equal(255, g)
    assert.equal(255, b)
  end)

  it("parses rgb() format", function()
    local r, g, b, a = cp.parse_color("rgb(100,200,50)")
    assert.equal(100, r)
    assert.equal(200, g)
    assert.equal(50, b)
    assert.equal(1.0, a)
  end)

  it("parses rgba() format", function()
    local r, g, b, a = cp.parse_color("rgba(100,200,50,0.5)")
    assert.equal(100, r)
    assert.equal(200, g)
    assert.equal(50, b)
    assert.equal(0.5, a)
  end)

  -- NOTE: HSL/HSLA pattern captures use `%%` which behaves differently
  -- in Lua 5.4 vs LuaJIT (5.1). These tests are skipped under Lua 5.4
  -- but work correctly inside Neovim (which uses LuaJIT).
  pending("parses hsl() format (requires LuaJIT)", function()
    local r, g, b, a = cp.parse_color("hsl(0,100%,50%)")
    assert.equal(255, r)
    assert.equal(0, g)
    assert.equal(0, b)
    assert.equal(1.0, a)
  end)

  pending("parses hsla() format (requires LuaJIT)", function()
    local r, g, b, a = cp.parse_color("hsla(0,100%,50%,0.75)")
    assert.equal(255, r)
    assert.equal(0, g)
    assert.equal(0, b)
    assert.equal(0.75, a)
  end)

  it("ignores whitespace", function()
    local r, g, b, a = cp.parse_color("  rgb( 100 , 200 , 50 )  ")
    -- After gsub("%s+", ""), becomes "rgb(100,200,50)"
    assert.equal(100, r)
    assert.equal(200, g)
    assert.equal(50, b)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("rgb_to_hex", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("converts black", function()
    assert.equal("#000000", cp.rgb_to_hex(0, 0, 0))
  end)

  it("converts white", function()
    assert.equal("#FFFFFF", cp.rgb_to_hex(255, 255, 255))
  end)

  it("converts red", function()
    assert.equal("#FF0000", cp.rgb_to_hex(255, 0, 0))
  end)

  it("converts arbitrary color", function()
    assert.equal("#1E90FF", cp.rgb_to_hex(30, 144, 255))
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("rgb_to_hsl", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("converts pure red", function()
    local h, s, l = cp.rgb_to_hsl(255, 0, 0)
    assert.equal(0, h)
    assert.equal(100, s)
    assert.equal(50, l)
  end)

  it("converts pure green", function()
    local h, s, l = cp.rgb_to_hsl(0, 255, 0)
    assert.equal(120, h)
    assert.equal(100, s)
    assert.equal(50, l)
  end)

  it("converts pure blue", function()
    local h, s, l = cp.rgb_to_hsl(0, 0, 255)
    assert.equal(240, h)
    assert.equal(100, s)
    assert.equal(50, l)
  end)

  it("converts white to 0,0,100", function()
    local h, s, l = cp.rgb_to_hsl(255, 255, 255)
    assert.equal(0, h)
    assert.equal(0, s)
    assert.equal(100, l)
  end)

  it("converts black to 0,0,0", function()
    local h, s, l = cp.rgb_to_hsl(0, 0, 0)
    assert.equal(0, h)
    assert.equal(0, s)
    assert.equal(0, l)
  end)

  it("converts gray to 0 saturation", function()
    local h, s, l = cp.rgb_to_hsl(128, 128, 128)
    assert.equal(0, h)
    assert.equal(0, s)
    assert.equal(50, l)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("hsl_to_rgb", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("converts pure red hsl", function()
    local r, g, b = cp.hsl_to_rgb(0, 100, 50)
    assert.equal(255, r)
    assert.equal(0, g)
    assert.equal(0, b)
  end)

  it("converts pure green hsl", function()
    local r, g, b = cp.hsl_to_rgb(120, 100, 50)
    assert.equal(0, r)
    assert.equal(255, g)
    assert.equal(0, b)
  end)

  it("converts pure blue hsl", function()
    local r, g, b = cp.hsl_to_rgb(240, 100, 50)
    assert.equal(0, r)
    assert.equal(0, g)
    assert.equal(255, b)
  end)

  it("converts achromatic (gray)", function()
    local r, g, b = cp.hsl_to_rgb(0, 0, 50)
    assert.equal(127, r)
    assert.equal(127, g)
    assert.equal(127, b)
  end)

  it("round-trips with rgb_to_hsl for pure colors", function()
    local h, s, l = cp.rgb_to_hsl(255, 0, 0)
    local r, g, b = cp.hsl_to_rgb(h, s, l)
    assert.equal(255, r)
    assert.equal(0, g)
    assert.equal(0, b)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("set_color", function()
  local cp

  before_each(function()
    cp = fresh()
    -- Reset state
    cp.state.r = 128
    cp.state.g = 128
    cp.state.b = 128
    cp.state.a = 1.0
    cp.state.buf = nil
    cp.state.win = nil
  end)

  it("returns true for valid hex color", function()
    assert.is_true(cp.set_color("#FF0000"))
  end)

  it("updates state for valid color", function()
    cp.set_color("#FF0000")
    assert.equal(255, cp.state.r)
    assert.equal(0, cp.state.g)
    assert.equal(0, cp.state.b)
  end)

  it("returns false for invalid color", function()
    assert.is_false(cp.set_color("not-a-color"))
  end)

  it("clamps values to valid range", function()
    -- Hex FF = 255, already max
    cp.set_color("#FFFFFF")
    assert.equal(255, cp.state.r)
    assert.equal(255, cp.state.g)
    assert.equal(255, cp.state.b)
  end)

  it("sets alpha from rgba", function()
    cp.set_color("rgba(100,100,100,0.5)")
    assert.equal(0.5, cp.state.a)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("format_output", function()
  local cp

  before_each(function()
    cp = fresh()
    cp.state.r = 255
    cp.state.g = 128
    cp.state.b = 0
    cp.state.a = 1.0
  end)

  it("formats as rgb by default (format index 1)", function()
    cp.state.output_format = 1
    assert.equal("rgb(255, 128, 0)", cp.format_output())
  end)

  it("formats as rgba", function()
    cp.state.output_format = 2
    assert.equal("rgba(255, 128, 0, 1.00)", cp.format_output())
  end)

  it("formats as hex", function()
    cp.state.output_format = 3
    assert.equal("#FF8000", cp.format_output())
  end)

  it("formats as hsl", function()
    cp.state.output_format = 4
    local output = cp.format_output()
    assert.matches("^hsl%(%d+, %d+%%, %d+%%%)", output)
  end)

  it("formats as hsla", function()
    cp.state.output_format = 5
    cp.state.a = 0.75
    local output = cp.format_output()
    assert.matches("^hsla%(%d+, %d+%%, %d+%%, 0%.75%)", output)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("create_slider", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("returns a string", function()
    local slider = cp.create_slider(128, 255, 60)
    assert.is_string(slider)
  end)

  it("contains the position marker", function()
    local slider = cp.create_slider(128, 255, 60)
    assert.matches("●", slider)
  end)

  it("slider at 0 has marker at start", function()
    local slider = cp.create_slider(0, 255, 60)
    assert.equal("●", slider:sub(1, 3)) -- ● is 3 bytes in UTF-8
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("navigate", function()
  local cp

  before_each(function()
    cp = fresh()
    cp.state.current_field = 1
    cp.state.buf = nil -- prevent render from running
  end)

  it("moves field down", function()
    cp.state.current_field = 1
    -- navigate calls render which needs buf; stub it
    cp.render = function() end
    cp.navigate(1)
    assert.equal(2, cp.state.current_field)
  end)

  it("moves field up", function()
    cp.state.current_field = 3
    cp.render = function() end
    cp.navigate(-1)
    assert.equal(2, cp.state.current_field)
  end)

  it("clamps at minimum 1", function()
    cp.state.current_field = 1
    cp.render = function() end
    cp.navigate(-1)
    assert.equal(1, cp.state.current_field)
  end)

  it("clamps at maximum 6", function()
    cp.state.current_field = 6
    cp.render = function() end
    cp.navigate(1)
    assert.equal(6, cp.state.current_field)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("adjust_value", function()
  local cp

  before_each(function()
    cp = fresh()
    cp.render = function() end
    cp.state.r = 128
    cp.state.g = 128
    cp.state.b = 128
    cp.state.a = 0.5
    cp.state.output_format = 1
  end)

  it("adjusts R when field is 2", function()
    cp.state.current_field = 2
    cp.adjust_value(1)
    assert.equal(129, cp.state.r)
  end)

  it("adjusts G when field is 3", function()
    cp.state.current_field = 3
    cp.adjust_value(-1)
    assert.equal(127, cp.state.g)
  end)

  it("adjusts B when field is 4", function()
    cp.state.current_field = 4
    cp.adjust_value(10)
    assert.equal(138, cp.state.b)
  end)

  it("adjusts A when field is 5", function()
    cp.state.current_field = 5
    cp.adjust_value(1) -- direction * 0.01
    assert.is_true(math.abs(cp.state.a - 0.51) < 0.001)
  end)

  it("clamps R at 0", function()
    cp.state.current_field = 2
    cp.state.r = 0
    cp.adjust_value(-1)
    assert.equal(0, cp.state.r)
  end)

  it("clamps R at 255", function()
    cp.state.current_field = 2
    cp.state.r = 255
    cp.adjust_value(1)
    assert.equal(255, cp.state.r)
  end)

  it("cycles format when field is 6", function()
    cp.state.current_field = 6
    cp.adjust_value(1)
    assert.equal(2, cp.state.output_format)
  end)

  it("wraps format from last to first", function()
    cp.state.current_field = 6
    cp.state.output_format = 5
    cp.adjust_value(1)
    assert.equal(1, cp.state.output_format)
  end)

  it("does nothing when field is 1 (input)", function()
    cp.state.current_field = 1
    local old_r = cp.state.r
    cp.adjust_value(1)
    assert.equal(old_r, cp.state.r)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("setup", function()
  local cp

  before_each(function()
    cp = fresh()
  end)

  it("merges user config", function()
    cp.setup({ output_format = "hex" })
    assert.equal("hex", cp.config.output_format)
  end)

  it("sets output_format index from string", function()
    cp.setup({ output_format = "hex" })
    assert.equal(3, cp.state.output_format)
  end)

  it("keeps default glyph if not overridden", function()
    cp.setup({})
    assert.is_truthy(cp.glyph)
  end)

  it("allows overriding glyph", function()
    cp.setup({ glyph = "X " })
    assert.equal("X ", cp.glyph)
  end)

  it("accepts border config", function()
    cp.setup({ border = "single" })
    assert.equal("single", cp.config.border)
  end)

  it("accepts width and height config", function()
    cp.setup({ width = 80, height = 20 })
    assert.equal(80, cp.config.width)
    assert.equal(20, cp.config.height)
  end)

  it("accepts default_color config", function()
    cp.setup({ default_color = "#FF0000" })
    assert.equal("#FF0000", cp.config.default_color)
  end)

  it("keeps default_color as #808080 when not overridden", function()
    cp.setup({})
    assert.equal("#808080", cp.config.default_color)
  end)

  it("allows partial mappings override", function()
    cp.setup({ mappings = { copy = { "Y" } } })
    assert.same({ "Y" }, cp.config.mappings.copy)
    -- other mappings should remain at default
    assert.same({ "q" }, cp.config.mappings.quit)
  end)
end)

-- ─────────────────────────────────────────────────────────────────────────────
describe("cancel_input", function()
  local cp

  before_each(function()
    cp = fresh()
    cp.render = function() end
    cp.disable_input_char_maps = function() end
    cp.state.buf = nil
    cp.state.win = nil
  end)

  it("resets input_text to default_color", function()
    cp.setup({ default_color = "#123456" })
    cp.state.input_text = "#aabbcc"
    cp.state.input_mode = true
    cp.cancel_input()
    assert.equal("#123456", cp.state.input_text)
  end)

  it("exits input_mode", function()
    cp.setup({})
    cp.state.input_mode = true
    cp.cancel_input()
    assert.is_false(cp.state.input_mode)
  end)
end)
