-- spec/support/vim_stub.lua
-- Minimal vim-API stub for running color-picker tests outside Neovim.

local _hl = {}

local vim_stub = {
  tbl_deep_extend = function(mode, ...)
    local result = {}
    local function deep_extend(t)
      for k, v in pairs(t) do
        if type(v) == "table" and type(result[k]) == "table" then
          local sub = {}
          for kk, vv in pairs(result[k]) do sub[kk] = vv end
          for kk, vv in pairs(v) do
            if type(vv) == "table" and type(sub[kk]) == "table" then
              local subsub = {}
              for kkk, vvv in pairs(sub[kk]) do subsub[kkk] = vvv end
              for kkk, vvv in pairs(vv) do subsub[kkk] = vvv end
              sub[kk] = subsub
            else
              sub[kk] = vv
            end
          end
          result[k] = sub
        else
          result[k] = v
        end
      end
    end
    for i = 1, select("#", ...) do
      local t = select(i, ...)
      if t then deep_extend(t) end
    end
    return result
  end,

  fn = {
    stdpath = function(what) return "/tmp/color_picker_test_" .. what end,
    setreg = function() end,
    strchars = function(s)
      -- Count UTF-8 characters
      local count = 0
      for _ in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        count = count + 1
      end
      return count
    end,
  },

  api = {
    nvim_set_hl = function(ns, name, opts)
      _hl[name] = opts
    end,
    nvim_get_hl = function(ns, opts)
      return _hl[opts.name] or {}
    end,
    nvim_create_buf = function() return 1 end,
    nvim_create_namespace = function() return 1 end,
    nvim_open_win = function() return 1 end,
    nvim_win_is_valid = function() return false end,
    nvim_buf_is_valid = function() return false end,
    nvim_win_close = function() end,
    nvim_win_get_width = function() return 60 end,
    nvim_win_get_height = function() return 14 end,
    nvim_buf_set_option = function() end,
    nvim_buf_set_lines = function() end,
    nvim_buf_add_highlight = function() end,
    nvim_win_set_cursor = function() end,
    nvim_win_set_config = function() end,
    nvim_create_user_command = function() end,
    nvim_create_autocmd = function() end,
  },

  keymap = {
    set = function() end,
    del = function() end,
  },

  cmd = function() end,

  pesc = function(s)
    return s:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  end,

  str_byteindex = function(s, idx)
    return idx
  end,

  str_utfindex = function(s, byte_idx)
    return byte_idx
  end,

  o = {
    lines = 24,
    columns = 80,
  },

  _hl = _hl,
}

return vim_stub
