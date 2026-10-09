-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Leader key (before lazy)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable netrw (use neo-tree instead)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Load plugins
require("lazy").setup("plugins")

-- Basic settings
vim.opt.number = true
vim.opt.relativenumber = false  -- Use absolute line numbers
vim.opt.mouse = "a"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.inccommand = "split"
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.termguicolors = true

-- Enable project-local configuration files
vim.opt.exrc = true
vim.opt.secure = true  -- Restrict dangerous commands in local configs

-- Auto-load .nvim.lua from project root
local config_file = vim.fn.getcwd() .. '/.nvim.lua'
if vim.fn.filereadable(config_file) == 1 then
  dofile(config_file)
end

-- Keymaps
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show [D]iagnostic in float" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- lazygit in a floating window, for the repo of the file you're in (nvim's
-- folder for a buffer without one). Like tmux's Ctrl+a g, but it works
-- outside tmux too. q in lazygit closes it, and buffers it changed on disk
-- (a discarded change) reload.
vim.keymap.set("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed here", vim.log.levels.WARN)
    return
  end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if not dir or vim.fn.isdirectory(dir) == 0 then dir = vim.fn.getcwd() end

  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.9)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor", style = "minimal", border = "rounded",
    title = " lazygit ", title_pos = "center",
    width = width, height = height,
    row = math.floor((vim.o.lines - height) / 2), col = math.floor((vim.o.columns - width) / 2),
  })
  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    cwd = dir,
    on_exit = vim.schedule_wrap(function()
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
      vim.cmd("checktime")
    end),
  })
  -- lazygit uses Esc to go back. The global <Esc><Esc> (leave terminal mode)
  -- would delay a single Esc and swallow a double one, so here Esc is lazygit's.
  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, nowait = true })
  vim.cmd("startinsert")
end, { desc = "Lazygit for this file's repo" })

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Move focus to the left window" })
vim.keymap.set("n", "<C-l>", "<C-w><C-l>", { desc = "Move focus to the right window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Move focus to the lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Move focus to the upper window" })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
