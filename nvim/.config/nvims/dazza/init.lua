-- basic
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 10
vim.opt.wrap = false

-- indent
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.autoindent = true

-- search
vim.opt.ignorecase = true
-- vim.opt.smartsearch = true
vim.opt.hlsearch = false -- try
vim.opt.incsearch = true

-- visual
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "120"
vim.opt.showmatch = true -- brackets
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 300

-- comepltions
vim.opt.completeopt = "menuone,noinsert,noselect,popup"
vim.opt.pumheight = 10

-- files
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false

-- behivior
vim.opt.hidden = true

vim.opt.iskeyword:append("-")
vim.opt.iskeyword:append("_")
vim.opt.path:append("**")

vim.opt.clipboard:append("unnamedplus")
vim.opt.modifiable = true
vim.opt.encoding = "UTF-8"

-- vim.opt.guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"
vim.opt.guicursor = "n-v-c:block,i-ci-ve:hor20"

-- Split behavior
vim.opt.splitbelow = true                          -- Horizontal splits go below
vim.opt.splitright = true                          -- Vertical splits go right

-- Folding settings
vim.opt.foldmethod = "expr"                        -- Use expression for folding
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"    -- Use treesitter for folding
vim.opt.foldlevel = 99 

-- KEY MAPS
vim.g.mapleader = " "
vim.g.localleader = " "

-- Move lines up/down
vim.keymap.set("n", "<A-S-j>", ":m .+1<CR>==", { desc = "Move line down" })
vim.keymap.set("n", "<A-S-k>", ":m .-2<CR>==", { desc = "Move line up" })
vim.keymap.set("v", "<A-S-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "<A-S-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Quick file navigation
vim.keymap.set("n", "<leader>e", ":Explore<CR>", { desc = "Open file explorer" })


vim.keymap.set("n", "J", "", { desc = "Join lines and keep cursor position" })


-- Splitting & Resizing
vim.keymap.set("n", "<leader>wsv", ":vsplit<CR>", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>wsh", ":split<CR>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<C-S-'>", ":resize +1<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<C-S-;>", ":resize -1<CR>", { desc = "Decrease window height" })
vim.keymap.set("n", "<C-;>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<C-'>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Quick config editing
vim.keymap.set("n", "<leader>ce", ":e $MYVIMRC<CR>", { desc = "Edit config" })
vim.keymap.set("n", "<leader>cr", ":so $MYVIMRC<CR>", { desc = "Reload config" })
