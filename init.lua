-- ===================================================================
-- Global Settings & Options
-- ===================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Editor appearance
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true

-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Tabs and indentation
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Disable netrw file explorer
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Custom function to close buffers
local function close_buffer()
  local buffers = vim.fn.getbufinfo({ buflisted = 1 })
  if #buffers > 1 then
    vim.cmd("bdelete")
  else
    vim.notify("Cannot close last buffer", vim.log.levels.WARN)
  end
end

-- Autocommand to make help files open in a full window
vim.api.nvim_create_autocmd("FileType", {
  pattern = "help",
  callback = function()
    vim.cmd("only")
    vim.bo.buflisted = true
  end,
})

-- ===================================================================
-- Bootstrap Lazy.nvim
-- ===================================================================
local lazypath = vim.fn.stdpath("data") .. "/site/pack/lazy/opt/lazy.nvim"
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

-- ===================================================================
-- Load and Configure Plugins
-- ===================================================================
require("lazy").setup({
  -- Colorscheme
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'tokyonight'
      vim.api.nvim_set_hl(0, 'LineNr', { fg = '#7a88a9' })
    end,
  },
-- Auto-pairs for brackets, quotes, etc.
-- Auto-pairs for brackets, quotes, etc.
{
  "windwp/nvim-autopairs",
  config = function()
    local npairs = require("nvim-autopairs")
    npairs.setup({
      check_ts = true,  -- use treesitter to better handle brackets
      fast_wrap = {},   -- optional, allows wrapping selections
    })

    -- Integrate with nvim-cmp
    local cmp_status, cmp = pcall(require, "cmp")
    if cmp_status then
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end
  end,
},
-- File Explorer (Oil.nvim)
  {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- for icons
    config = function()
      require('oil').setup()
    end,
  },

  -- Syntax Highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- LSP and Mason
  { "neovim/nvim-lspconfig" },
  { "mfussenegger/nvim-jdtls" },
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({ ensure_installed = { "jdtls" } })
    end,
  },

  -- Autocomplete
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
        'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path',
        'L3MON4D3/LuaSnip', 'saadparwaiz1/cmp_luasnip',
    },
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')
        cmp.setup({
            snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
            mapping = cmp.mapping.preset.insert({
                ['<C-Space>'] = cmp.mapping.complete(),
                ['<CR>'] = cmp.mapping.confirm({ select = true }),
                ['<Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then cmp.select_next_item()
                    elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
                    else fallback() end
                end, { "i", "s" }),
                ['<S-Tab>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then cmp.select_prev_item()
                    elseif luasnip.jumpable(-1) then luasnip.jump(-1)
                    else fallback() end
                end, { "i", "s" }),
            }),
            sources = cmp.config.sources({
                { name = 'nvim_lsp' }, { name = 'luasnip' },
                { name = 'buffer' }, { name = 'path' },
            })
        })
    end,
  },

  -- UI Enhancements
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        require('lualine').setup({ options = { theme = 'tokyonight' } })
    end,
  },
  {
    'akinsho/bufferline.nvim',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function () require('bufferline').setup({}) end,
  },
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },

  -- Git
  { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end },

  -- Copilot
  { 'github/copilot.vim' },
})

-- ===================================================================
-- Keymaps
-- ===================================================================
-- Open file explorer
vim.keymap.set("n", "<Tab>", function() require("oil").open() end, { desc = "Open file explorer" })

-- Move lines up/down
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { silent = true, desc = "Move line down" })
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { silent = true, desc = "Move line up" })
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { silent = true, desc = "Move selection down" })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { silent = true, desc = "Move selection up" })

-- Unhighlight search results
vim.keymap.set("n", "<leader>h", ":noh<CR>", { silent = true, desc = "Clear search highlight" })

-- Terminal
vim.keymap.set("n", [[<C-\>]], ":terminal<CR>i", { desc = "Open terminal" })
vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

-- Saving & Quitting
vim.keymap.set("n", "<F5>", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<F6>", ":wa<CR>", { desc = "Save all files" })
vim.keymap.set("n", "<BS>", close_buffer, { desc = "Close buffer" })
vim.keymap.set("n", "<C-BS>", ":qa<CR>", { desc = "Quit all" })

-- Bufferline navigation
vim.keymap.set('n', '<C-h>', ':BufferLineCyclePrev<CR>', { desc = "Previous buffer" })
vim.keymap.set('n', '<C-l>', ':BufferLineCycleNext<CR>', { desc = "Next buffer" })

-- Copilot
vim.keymap.set('i', '<C-e>', '<Plug>(copilot-dismiss)', { desc = "Dismiss Copilot suggestion" })
vim.keymap.set({ "n", "v" }, "~", ":CopilotChat<CR>", { desc = "Open Copilot Chat" })

-- Telescope
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end, { desc = "Find Files" })
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end, { desc = "Live Grep" })
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers() end, { desc = 'Find Buffers' })

-- Java compilation
vim.api.nvim_set_keymap('n', '<F5>',
  ':w<CR>:cd %:p:h<CR>:!mkdir -p out && javac -d out % && java -cp out %:t:r<CR>',
  { noremap = true, silent = true })
