return {
  -- load from a local folder:
  dir = vim.fn.stdpath('config') .. '/lua/plugins/color-picker.nvim',
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
