local M = {}

local api = vim.api
local fn = vim.fn

-- ─── Type Annotations ────────────────────────────────────────────────────────

---@class ColorPickerMappings
---@field quit        string[]  Keys to close the picker
---@field escape      string[]  Keys to cancel input / close
---@field nav_down    string[]  Keys to move to the next field
---@field nav_up      string[]  Keys to move to the previous field
---@field dec         string[]  Keys to decrease the current value by 1
---@field inc         string[]  Keys to increase the current value by 1
---@field dec_big     string[]  Keys to decrease the current value by 10
---@field inc_big     string[]  Keys to increase the current value by 10
---@field copy        string[]  Keys to copy the formatted output to clipboard
---@field input       string[]  Keys to enter / confirm input mode

---@class ColorPickerConfig
---@field glyph         string              Symbol shown next to channel sliders
---@field output_format string              Default output format (rgb|rgba|hex|hsl|hsla)
---@field border        string|string[]     Floating window border style (see :h nvim_open_win)
---@field width         integer             Floating window width in columns
---@field height        integer             Floating window height in rows
---@field default_color string              Color used when opening without an argument
---@field mappings      ColorPickerMappings Keymap overrides

---@class ColorPickerState
---@field r             integer   Red channel   (0–255)
---@field g             integer   Green channel (0–255)
---@field b             integer   Blue channel  (0–255)
---@field a             number    Alpha channel (0.0–1.0)
---@field current_field integer   1=input 2=R 3=G 4=B 5=A 6=format
---@field output_format integer   Index into formats list
---@field buf           integer?  Buffer handle of the picker window
---@field win           integer?  Window handle of the picker window
---@field ns            integer?  Namespace id for highlights
---@field input_text    string    Current text in the input field
---@field input_mode    boolean   Whether character-by-character input is active

-- ─── Defaults ────────────────────────────────────────────────────────────────

---@type ColorPickerConfig
M.config = {
    glyph         = '󱓻 ',
    output_format = 'rgb',
    border        = 'rounded',
    width         = 60,
    height        = 14,
    default_color = '#808080',
    mappings      = {
        quit      = { 'q' },
        escape    = { '<Esc>' },
        nav_down  = { 'j', '<Down>' },
        nav_up    = { 'k', '<Up>' },
        dec       = { 'h', '<Left>' },
        inc       = { 'l', '<Right>' },
        dec_big   = { 'H', '<S-Left>' },
        inc_big   = { 'L', '<S-Right>' },
        copy      = { 'y' },
        input     = { 'i', '<CR>' },
    },
}

---@type ColorPickerState
M.state = {
    r             = 128,
    g             = 128,
    b             = 128,
    a             = 1.0,
    current_field = 1,
    output_format = 1,
    buf           = nil,
    win           = nil,
    ns            = nil,
    input_text    = '',
    input_mode    = false,
}

---@type string[]
local formats = { 'rgb', 'rgba', 'hex', 'hsl', 'hsla' }

-- ─── Color Math ──────────────────────────────────────────────────────────────

---Convert RGB to HSL.
---@param r integer  0–255
---@param g integer  0–255
---@param b integer  0–255
---@return integer h  0–360
---@return integer s  0–100
---@return integer l  0–100
function M.rgb_to_hsl(r, g, b)
    r, g, b = r / 255, g / 255, b / 255
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local h, s, l = 0, 0, (max + min) / 2

    if max ~= min then
        local d = max - min
        s = l > 0.5 and d / (2 - max - min) or d / (max + min)
        if max == r then
            h = (g - b) / d + (g < b and 6 or 0)
        elseif max == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h / 6
    end

    return math.floor(h * 360), math.floor(s * 100), math.floor(l * 100)
end

---Convert RGB to uppercase hex string including '#' prefix.
---@param r integer  0–255
---@param g integer  0–255
---@param b integer  0–255
---@return string    e.g. "#FF8000"
function M.rgb_to_hex(r, g, b)
    return string.format('#%02x%02x%02x', r, g, b):upper()
end

---Convert HSL to RGB.
---@param h integer  0–360
---@param s integer  0–100
---@param l integer  0–100
---@return integer r  0–255
---@return integer g  0–255
---@return integer b  0–255
function M.hsl_to_rgb(h, s, l)
    h, s, l = h / 360, s / 100, l / 100
    local r, g, b

    if s == 0 then
        r, g, b = l, l, l
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s
        local p = 2 * l - q
        r = hue2rgb(p, q, h + 1 / 3)
        g = hue2rgb(p, q, h)
        b = hue2rgb(p, q, h - 1 / 3)
    end

    return math.floor(r * 255), math.floor(g * 255), math.floor(b * 255)
end

-- ─── Parsing & Formatting ─────────────────────────────────────────────────────

---Parse a color string into r, g, b, a components.
---Supported formats: #rrggbb, #rgb, rrggbb, rgb(), rgba(), hsl(), hsla()
---@param color_string? string
---@return integer? r
---@return integer? g
---@return integer? b
---@return number?  a
function M.parse_color(color_string)
    if not color_string or type(color_string) ~= 'string' then return nil end

    color_string = color_string:gsub('%s+', '')

    -- Hex (#rgb or #rrggbb)
    local hex = color_string:match('^#?([%da-fA-F]+)$')
    if hex then
        if #hex == 3 then hex = hex:gsub('.', '%1%1') end
        if #hex == 6 then
            local r = tonumber(hex:sub(1, 2), 16)
            local g = tonumber(hex:sub(3, 4), 16)
            local b = tonumber(hex:sub(5, 6), 16)
            return r, g, b, 1.0
        end
    end

    -- rgb()
    local r, g, b = color_string:match('^rgb%((%d+),(%d+),(%d+)%)$')
    if r then return tonumber(r), tonumber(g), tonumber(b), 1.0 end

    -- rgba()
    local r2, g2, b2, a2 =
        color_string:match('^rgba%((%d+),(%d+),(%d+),([%d%.]+)%)$')
    if r2 then return tonumber(r2), tonumber(g2), tonumber(b2), tonumber(a2) end

    -- hsl()
    local h, s, l = color_string:match('^hsl%((%d+),(%d+)%%,(%d+)%%)$')
    if h then
        local r3, g3, b3 = M.hsl_to_rgb(tonumber(h), tonumber(s), tonumber(l))
        return r3, g3, b3, 1.0
    end

    -- hsla()
    local h2, s2, l2, a3 =
        color_string:match('^hsla%((%d+),(%d+)%%,(%d+)%%,([%d%.]+)%)$')
    if h2 then
        local r4, g4, b4 = M.hsl_to_rgb(tonumber(h2), tonumber(s2), tonumber(l2))
        return r4, g4, b4, tonumber(a3)
    end

    return nil
end

---Set the picker state from a color string.
---@param color_string string
---@return boolean  true if color was valid and state was updated
function M.set_color(color_string)
    local r, g, b, a = M.parse_color(color_string)
    if r and g and b and a then
        M.state.r = math.max(0, math.min(255, r))
        M.state.g = math.max(0, math.min(255, g))
        M.state.b = math.max(0, math.min(255, b))
        M.state.a = math.max(0, math.min(1, a))
        if
            M.state.buf and api.nvim_buf_is_valid(M.state.buf)
            and M.state.win and api.nvim_win_is_valid(M.state.win)
        then
            M.render()
        end
        return true
    end
    return false
end

---Format the current color according to the active output format.
---@return string
function M.format_output()
    local r, g, b, a = M.state.r, M.state.g, M.state.b, M.state.a
    local fmt = formats[M.state.output_format]

    if fmt == 'rgb' then
        return string.format('rgb(%d, %d, %d)', r, g, b)
    elseif fmt == 'rgba' then
        return string.format('rgba(%d, %d, %d, %.2f)', r, g, b, a)
    elseif fmt == 'hex' then
        return M.rgb_to_hex(r, g, b)
    elseif fmt == 'hsl' then
        local h, s, l = M.rgb_to_hsl(r, g, b)
        return string.format('hsl(%d, %d%%, %d%%)', h, s, l)
    elseif fmt == 'hsla' then
        local h, s, l = M.rgb_to_hsl(r, g, b)
        return string.format('hsla(%d, %d%%, %d%%, %.2f)', h, s, l, a)
    end
    return ''
end

-- ─── Rendering Helpers ────────────────────────────────────────────────────────

---Build a slider string for the given value.
---@param value     number   Current value
---@param max_value number   Maximum value
---@param width     integer  Window width (columns)
---@return string
function M.create_slider(value, max_value, width)
    local slider_width = width - 13
    local position = math.floor((value / max_value) * slider_width)

    local parts = {}
    for i = 1, slider_width + 1 do
        parts[i] = (i == position + 1) and '●' or '─'
    end
    return table.concat(parts)
end

---Set up / refresh the ColorPickerPreview highlight group with the current color.
function M.create_highlight()
    local hex_color = M.rgb_to_hex(M.state.r, M.state.g, M.state.b)
    vim.cmd(string.format('highlight ColorPickerPreview guibg=%s guifg=%s', hex_color, hex_color))
end

---Update the floating window title to show the current hex value.
function M.update_title()
    if not M.state.win or not api.nvim_win_is_valid(M.state.win) then return end
    local hex = M.rgb_to_hex(M.state.r, M.state.g, M.state.b)
    api.nvim_win_set_config(M.state.win, {
        title     = string.format(' Color Picker  %s ', hex),
        title_pos = 'center',
    })
end

-- ─── Main Render ─────────────────────────────────────────────────────────────

---Re-draw the picker buffer.
function M.render()
    if not M.state.buf or not api.nvim_buf_is_valid(M.state.buf) then return end

    local win_width = api.nvim_win_get_width(M.state.win)

    local lines      = {}
    local highlights = {}

    local function hl(line_idx, col_start, col_end, group)
        table.insert(highlights, { line = line_idx, start = col_start, finish = col_end, hl_group = group })
    end

    -- Initialize highlight groups (link to built-in groups so themes work)
    vim.cmd [[
        highlight default link ColorPickerSelected CursorLine
        highlight default link ColorPickerOutput   Special
        highlight default link ColorPickerLabel    Identifier
    ]]

    -- ── Row 0: blank padding ──────────────────────────────────────────────────
    table.insert(lines, '')

    -- ── Row 1: Input field ────────────────────────────────────────────────────
    local input_selected = (M.state.current_field == 1)
    local marker_str     = input_selected and '▶ ' or '  '
    local label_str      = 'Input: '
    local disp_str       = (M.state.input_text ~= '' and M.state.input_text or M.config.default_color) .. ' '
    local pad            = math.max(0, math.floor((win_width - #marker_str - #label_str - #disp_str) / 2))
    local input_line     = string.rep(' ', pad) .. marker_str .. label_str .. disp_str
    local input_line_idx = #lines
    table.insert(lines, input_line)

    if input_selected then
        hl(input_line_idx, 0, -1, 'ColorPickerSelected')
        if M.state.input_mode then
            api.nvim_win_set_cursor(M.state.win, { #lines, #input_line + 1 })
        end
    end

    -- ── Row 2: blank ─────────────────────────────────────────────────────────
    table.insert(lines, '')

    -- ── Rows 3-6: Channel sliders ─────────────────────────────────────────────
    local channels = {
        { label = 'R', key = 'r', field = 2, max = 255, fmt = '%3d',  val_fn = function() return M.state.r end },
        { label = 'G', key = 'g', field = 3, max = 255, fmt = '%3d',  val_fn = function() return M.state.g end },
        { label = 'B', key = 'b', field = 4, max = 255, fmt = '%3d',  val_fn = function() return M.state.b end },
        { label = 'A', key = 'a', field = 5, max = 100, fmt = '%.2f', val_fn = function() return M.state.a end },
    }

    -- Per-channel color highlight groups
    local chan_hls = {
        ColorPickerR = string.format('#%02x0000', M.state.r),
        ColorPickerG = string.format('#00%02x00', M.state.g),
        ColorPickerB = string.format('#0000%02x', M.state.b),
    }
    -- ensure minimum brightness so zero-values aren't invisible
    local MIN_BRIGHT = 0x44
    chan_hls.ColorPickerR = string.format('#%02x0000', math.max(M.state.r, MIN_BRIGHT))
    chan_hls.ColorPickerG = string.format('#00%02x00', math.max(M.state.g, MIN_BRIGHT))
    chan_hls.ColorPickerB = string.format('#0000%02x', math.max(M.state.b, MIN_BRIGHT))

    for name, fg in pairs(chan_hls) do
        vim.cmd(string.format('highlight %s guifg=%s', name, fg))
    end

    local chan_hl_map = { 'ColorPickerR', 'ColorPickerG', 'ColorPickerB', nil }

    for i, ch in ipairs(channels) do
        local selected = (M.state.current_field == ch.field)
        local mk       = selected and '▶ ' or '  '
        local raw_val  = ch.val_fn()
        local slider_val = (ch.label == 'A') and raw_val * 100 or raw_val
        local slider  = M.create_slider(slider_val, ch.max, win_width)
        local glyph   = M.glyph

        local val_str
        if ch.label == 'A' then
            val_str = string.format('%.2f', raw_val)
        else
            val_str = string.format('%3d', raw_val)
        end

        local row   = string.format('%s%s: %s %s%s', mk, ch.label, val_str, glyph, slider)
        local row_i = #lines
        table.insert(lines, row)

        if selected then
            hl(row_i, 0, -1, 'ColorPickerSelected')
        end

        -- Glyph color highlight (RGB channels only)
        if chan_hl_map[i] then
            local trimmed = glyph:gsub('%s+$', '')
            if trimmed ~= '' then
                local text = row
                local _, after_val = text:find('^%s*..%u:%s*[%d%.]+%s+')
                local start_pos = after_val and (after_val + 1) or 1
                local gs = text:find(vim.pesc(trimmed), start_pos, true)
                if gs then
                    local gc  = fn.strchars(trimmed)
                    local sb  = gs - 1
                    local eb  = vim.str_byteindex(text, (vim.str_utfindex(text, gs - 1) + gc))
                    if not eb or eb < sb then eb = sb + #trimmed end
                    hl(row_i, sb, eb, chan_hl_map[i])
                end
            end
        end
    end

    -- ── Separator ─────────────────────────────────────────────────────────────
    table.insert(lines, '')
    local sep_line_idx = #lines
    table.insert(lines, string.rep('─', win_width))
    hl(sep_line_idx, 0, -1, 'Comment')

    -- ── Color preview row ─────────────────────────────────────────────────────
    local preview_sym  = ' '
    local preview_text = string.rep(preview_sym .. ' ', math.floor(win_width / 2))
    local preview_idx  = #lines
    table.insert(lines, preview_text)
    hl(preview_idx, 0, #preview_text, 'ColorPickerPreview')

    -- ── Separator ─────────────────────────────────────────────────────────────
    local sep2_idx = #lines
    table.insert(lines, string.rep('─', win_width))
    hl(sep2_idx, 0, -1, 'Comment')

    -- ── Format selector ───────────────────────────────────────────────────────
    local fmt_selected = (M.state.current_field == 6)
    local fmt_mk       = fmt_selected and '▶ ' or '  '
    local fmt_base     = string.format('Format: %s', formats[M.state.output_format])
    local fmt_pad      = math.max(0, math.floor((win_width - #fmt_base - 2) / 2))
    local fmt_idx      = #lines
    local fmt_line     = string.rep(' ', fmt_pad) .. fmt_mk .. fmt_base
    table.insert(lines, fmt_line)

    if fmt_selected then
        hl(fmt_idx, 0, -1, 'ColorPickerSelected')
    end
    -- Highlight the format name
    local fmt_name_start = #fmt_line - #formats[M.state.output_format]
    hl(fmt_idx, fmt_name_start, -1, 'ColorPickerLabel')

    -- ── Output value ──────────────────────────────────────────────────────────
    local output      = M.format_output()
    local out_pad     = math.max(0, math.floor((win_width - #output) / 2))
    local out_idx     = #lines
    local out_line    = string.rep(' ', out_pad) .. output
    table.insert(lines, out_line)
    hl(out_idx, out_pad, out_pad + #output, 'ColorPickerOutput')

    table.insert(lines, '')

    -- ── Help bar ──────────────────────────────────────────────────────────────
    local help
    if M.state.input_mode then
        help = ' Type color │ Enter: Apply │ Esc: Cancel '
    else
        help = ' ↑↓/jk: Nav │ ←→/hl: Adjust │ H/L: ±10 │ i: Input │ y: Copy │ q: Quit '
    end
    local help_pad = math.max(0, math.floor((win_width - #help) / 2))
    local help_idx = #lines
    table.insert(lines, string.rep(' ', help_pad) .. help)

    -- Write lines
    api.nvim_buf_set_option(M.state.buf, 'modifiable', true)
    api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(M.state.buf, 'modifiable', false)

    -- Apply highlights
    M.create_highlight()
    M.update_title()

    for _, h_entry in ipairs(highlights) do
        api.nvim_buf_add_highlight(
            M.state.buf, M.state.ns,
            h_entry.hl_group, h_entry.line,
            h_entry.start, h_entry.finish
        )
    end

    api.nvim_buf_add_highlight(M.state.buf, M.state.ns, 'Comment', help_idx, 0, -1)
end

-- ─── Actions ─────────────────────────────────────────────────────────────────

---Adjust the current field's value by `direction` (±1 or ±10).
---@param direction integer
function M.adjust_value(direction)
    local f = M.state.current_field
    if f == 2 then
        M.state.r = math.max(0, math.min(255, M.state.r + direction))
    elseif f == 3 then
        M.state.g = math.max(0, math.min(255, M.state.g + direction))
    elseif f == 4 then
        M.state.b = math.max(0, math.min(255, M.state.b + direction))
    elseif f == 5 then
        M.state.a = math.max(0, math.min(1, M.state.a + direction * 0.01))
    elseif f == 6 then
        M.state.output_format = ((M.state.output_format - 1 + direction) % #formats) + 1
    end
    M.render()
end

---Move focus to the next or previous field.
---@param direction integer  +1 or -1
function M.navigate(direction)
    M.state.current_field = math.max(1, math.min(6, M.state.current_field + direction))
    M.render()
end

---Handle a single printable character in input mode.
---@param char string  A single character
function M.handle_input_char(char)
    if M.state.current_field == 1 and M.state.input_mode then
        if char == '\b' or char == '\127' then
            M.state.input_text = M.state.input_text:sub(1, -2)
        else
            M.state.input_text = M.state.input_text .. char
        end
        M.render()
    end
end

---Try to apply the text currently in the input field.
---@return boolean  true if the color was valid and applied
function M.apply_input()
    if M.state.input_text and M.state.input_text ~= '' then
        if M.set_color(M.state.input_text) then
            M.state.input_mode = false
            if M.disable_input_char_maps then M.disable_input_char_maps() end
            M.render()
            return true
        end
    end
    return false
end

---Copy the currently formatted output to the system clipboard.
function M.copy_to_clipboard()
    local output = M.format_output()
    fn.setreg('+', output)
    fn.setreg('*', output)
    vim.notify('Copied: ' .. output, vim.log.levels.INFO)
end

---Cancel input mode and reset to the default color.
function M.cancel_input()
    M.state.input_text = M.config.default_color
    M.set_color(M.state.input_text)
    M.state.input_mode = false
    if M.disable_input_char_maps then M.disable_input_char_maps() end
    M.render()
end

-- ─── Keymaps ─────────────────────────────────────────────────────────────────

---Register all buffer-local keymaps, driven by M.config.mappings.
function M.setup_keymaps()
    local buf = M.state.buf
    local maps = M.config.mappings

    local function map(keys, fn_cb)
        for _, key in ipairs(keys) do
            vim.keymap.set('n', key, fn_cb, { buffer = buf, noremap = true, silent = true })
        end
    end

    -- Character-capture helpers (input mode)
    M._input_mapped_keys = {}

    function M.enable_input_char_maps()
        if not (buf and api.nvim_buf_is_valid(buf)) then return end
        local excluded = { q = true }
        for i = 32, 126 do
            local char = string.char(i)
            if not excluded[char] then
                vim.keymap.set('n', char, function()
                    if M.state.current_field == 1 and M.state.input_mode then
                        M.handle_input_char(char)
                    end
                end, { buffer = buf, noremap = true, silent = true })
                table.insert(M._input_mapped_keys, char)
            end
        end
        vim.keymap.set('n', '<BS>', function()
            if M.state.current_field == 1 and M.state.input_mode then
                M.handle_input_char('\b')
            end
        end, { buffer = buf, noremap = true, silent = true })
        table.insert(M._input_mapped_keys, '<BS>')
    end

    function M.disable_input_char_maps()
        if not (buf and api.nvim_buf_is_valid(buf)) then return end
        for _, key in ipairs(M._input_mapped_keys or {}) do
            pcall(vim.keymap.del, 'n', key, { buffer = buf })
        end
        M._input_mapped_keys = {}
    end

    -- quit
    map(maps.quit, function()
        if M.state.input_mode then M.disable_input_char_maps() end
        M.close()
    end)

    -- escape / cancel
    map(maps.escape, function()
        if M.state.input_mode then
            M.cancel_input()
        else
            M.close()
        end
    end)

    -- navigation
    map(maps.nav_down, function()
        if not M.state.input_mode then M.navigate(1) end
    end)
    map(maps.nav_up, function()
        if not M.state.input_mode then M.navigate(-1) end
    end)

    -- fine adjust
    map(maps.dec, function()
        if not M.state.input_mode then M.adjust_value(-1) end
    end)
    map(maps.inc, function()
        if not M.state.input_mode then M.adjust_value(1) end
    end)

    -- coarse adjust
    map(maps.dec_big, function()
        if not M.state.input_mode then M.adjust_value(-10) end
    end)
    map(maps.inc_big, function()
        if not M.state.input_mode then M.adjust_value(10) end
    end)

    -- copy
    map(maps.copy, M.copy_to_clipboard)

    -- enter / confirm input
    local function enter_input()
        if M.state.current_field == 1 and M.state.input_mode then
            M.apply_input()
        else
            M.state.current_field = 1
            M.state.input_mode    = true
            M.enable_input_char_maps()
            M.render()
        end
    end
    -- 'i' always enters input mode; other input keys toggle/confirm
    vim.keymap.set('n', 'i', function()
        M.state.current_field = 1
        M.state.input_mode    = true
        M.enable_input_char_maps()
        M.render()
    end, { buffer = buf, noremap = true, silent = true })

    local remaining_input_keys = vim.tbl_filter(function(k) return k ~= 'i' end, maps.input)
    for _, key in ipairs(remaining_input_keys) do
        vim.keymap.set('n', key, enter_input, { buffer = buf, noremap = true, silent = true })
    end
end

-- ─── Window Management ────────────────────────────────────────────────────────

---Re-center the floating window after a terminal resize.
function M.recenter_window()
    if not M.state.win or not api.nvim_win_is_valid(M.state.win) then return end

    local w = M.config.width
    local h = M.config.height
    api.nvim_win_set_config(M.state.win, {
        relative = 'editor',
        width    = w,
        height   = h,
        row      = math.floor((vim.o.lines   - h) / 2),
        col      = math.floor((vim.o.columns - w) / 2),
    })
end

---Open the color picker floating window.
---@param initial_color? string  Optional starting color string
function M.open(initial_color)
    -- Close existing instance if open
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        M.close()
    end

    M.state.buf = api.nvim_create_buf(false, true)
    M.state.ns  = api.nvim_create_namespace('color_picker')

    if initial_color and initial_color ~= '' then
        M.set_color(initial_color)
        M.state.input_text = initial_color
    else
        M.state.input_text = M.config.default_color
        M.set_color(M.state.input_text)
    end

    local w   = M.config.width
    local h   = M.config.height
    local hex = M.rgb_to_hex(M.state.r, M.state.g, M.state.b)

    local win_opts = {
        relative  = 'editor',
        width     = w,
        height    = h,
        row       = math.floor((vim.o.lines   - h) / 2),
        col       = math.floor((vim.o.columns - w) / 2),
        style     = 'minimal',
        border    = M.config.border,
        title     = string.format(' Color Picker  %s ', hex),
        title_pos = 'center',
        mouse     = true,
    }

    M.state.win = api.nvim_open_win(M.state.buf, true, win_opts)

    api.nvim_buf_set_option(M.state.buf, 'bufhidden', 'wipe')
    api.nvim_buf_set_option(M.state.buf, 'buftype',   'nofile')
    api.nvim_buf_set_option(M.state.buf, 'swapfile',  false)
    api.nvim_buf_set_option(M.state.buf, 'filetype',  'colorpicker')

    vim.api.nvim_create_autocmd('VimResized', {
        callback = M.recenter_window,
        buffer   = M.state.buf,
    })

    M.setup_keymaps()
    M.render()
end

---Close the color picker window.
function M.close()
    if M.state.win and api.nvim_win_is_valid(M.state.win) then
        api.nvim_win_close(M.state.win, true)
    end
    M.state.win = nil
    M.state.buf = nil
end

-- ─── Setup ───────────────────────────────────────────────────────────────────

---Configure and initialise the plugin.
---@param opts? ColorPickerConfig  Partial config table; merged over defaults
function M.setup(opts)
    opts = opts or {}

    -- Deep-merge mappings separately to allow partial overrides per action
    local merged_maps = vim.tbl_deep_extend('force', M.config.mappings, opts.mappings or {})
    M.config = vim.tbl_deep_extend('force', M.config, opts)
    M.config.mappings = merged_maps

    M.glyph = M.config.glyph

    -- Map output_format string → index
    if type(M.config.output_format) == 'string' then
        for i, name in ipairs(formats) do
            if name == M.config.output_format then
                M.state.output_format = i
                break
            end
        end
    end

    vim.api.nvim_create_user_command('ColorPicker', function(cmd_opts)
        local color = cmd_opts.args ~= '' and cmd_opts.args or nil
        M.open(color)
    end, { nargs = '?' })

    vim.keymap.set('n', '<leader>cp', M.open, { desc = 'Open Color Picker' })
end

return M
