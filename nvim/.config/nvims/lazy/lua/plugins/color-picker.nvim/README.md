# color-picker.nvim

An interactive color picker for Neovim with RGB/HSL sliders and multiple output formats.

## Features

- Interactive floating window with RGB, alpha sliders and color preview
- Input field to type colors directly (hex, rgb, rgba, hsl, hsla)
- Multiple output formats: `rgb`, `rgba`, `hex`, `hsl`, `hsla`
- Copy formatted color to clipboard (`y`)
- Keyboard-driven navigation with configurable keymaps
- Selected-field highlight and dynamic window title showing current hex
- Fully configurable: border, size, default color, keymaps
- LuaLS / EmmyLua type annotations for IDE support

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  -- load from a local folder:
  dir = vim.fn.expand('~/github.com/gzitei/color-picker.nvim'),
  cmd  = 'ColorPicker',
  keys = {
    { '<leader>cp', desc = 'Open Color Picker' },
  },
  opts = {
    glyph         = '󱓻 ',
    output_format = 'hex',
    border        = 'rounded',
    default_color = '#808080',
  },
}
```

## Usage

| Command / Key      | Action                               |
|--------------------|--------------------------------------|
| `:ColorPicker`     | Open picker (uses `default_color`)   |
| `:ColorPicker #FF0000` | Open with a specific color       |
| `<leader>cp`       | Open picker                          |
| `j` / `k`          | Navigate fields                      |
| `h` / `l`          | Adjust value ±1                      |
| `H` / `L`          | Adjust value ±10                     |
| `i` / `Enter`      | Enter / confirm text input           |
| `y`                | Copy formatted output to clipboard   |
| `Esc`              | Cancel input or close                |
| `q`                | Close                                |

## Configuration

All keys are optional. Shown with their defaults:

```lua
require('color-picker').setup({
  -- Symbol shown next to channel sliders
  glyph         = '󱓻 ',

  -- Default output format: 'rgb' | 'rgba' | 'hex' | 'hsl' | 'hsla'
  output_format = 'rgb',

  -- Floating window border (see :h nvim_open_win)
  border        = 'rounded',

  -- Window dimensions
  width         = 60,
  height        = 14,

  -- Color used when opening without an argument
  default_color = '#808080',

  -- Override individual keymaps (each value is a list of keys)
  mappings = {
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
})
```

## Development

### Running Tests

```bash
make test
```

Requires [busted](https://lunarmodules.github.io/busted/):

```bash
luarocks install busted
```
