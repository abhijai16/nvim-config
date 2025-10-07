-- ===================================================================
-- Global Settings & Options
-- ===================================================================
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Editor appearance
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 50


-- Clipboard
vim.opt.clipboard = 'unnamedplus'

-- Tabs and indentation
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Disable netrw
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

-- Help files open in full window
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
-- Plugins
-- ===================================================================
require("lazy").setup({
  -- Colorschemes
  { 'folke/tokyonight.nvim', lazy = false, priority = 1000 },
  { 'rebelot/kanagawa.nvim' },
  { 'EdenEast/nightfox.nvim' },
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'shaunsingh/nord.nvim' },

  -- Auto-pairs
  {
    "windwp/nvim-autopairs",
    config = function()
      local npairs = require("nvim-autopairs")
      npairs.setup({ check_ts = true, fast_wrap = {} })
      local cmp_status, cmp = pcall(require, "cmp")
      if cmp_status then
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end
    end,
  },

  -- Oil file explorer
  {
    'stevearc/oil.nvim',
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function() require('oil').setup() end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {"java", "typescript", "c", "cpp", "python", "lua", "rust","javascript"},
        sync_install = false,
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Mason & LSP
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "jdtls", "pyright", "clangd" },
      })
    end,
  },

  -- LSPconfig
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local on_attach = function(_, bufnr)
        local opts = { buffer = bufnr, noremap = true, silent = true }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
      end

      local servers = { "jdtls", "pyright", "clangd" }
      for _, name in ipairs(servers) do
        lspconfig[name].setup({
          on_attach = on_attach,
          capabilities = vim.lsp.protocol.make_client_capabilities(),
        })
      end
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
          ['<C-y>'] = cmp.mapping.confirm({ select = true }),
          ['<C-n>'] = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ['<C-p>'] = cmp.mapping(function(fallback)
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

  -- UI
  { 'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' } },
  { 'akinsho/bufferline.nvim', dependencies = 'nvim-tree/nvim-web-devicons' },
  { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- Git
  { 'lewis6991/gitsigns.nvim', config = function() require('gitsigns').setup() end },

  -- Copilot
  { 'github/copilot.vim' },

  -- ToggleTerm for bottom terminal
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup{
        size = 15,
        open_mapping = [[<C-\>]],
        shade_terminals = true,
        direction = "horizontal",
        close_on_exit = false,
        shell = vim.o.shell,
      }
    end,
  },
})

-- ===================================================================
-- Bufferline Setup (VS Code-like)
-- ===================================================================
require("bufferline").setup({
  options = {
    numbers = "ordinal",           -- show buffer numbers
    close_command = "bdelete! %d", -- close buffer
    right_mouse_command = "bdelete! %d",
    left_mouse_command = "buffer %d",
    middle_mouse_command = nil,
    indicator_icon = '▎',           -- current buffer indicator
    buffer_close_icon = '🗙',       -- close icon on right
    modified_icon = '●',           -- modified indicator
    close_icon = '⛒',              -- global close icon
    left_trunc_marker = '',
    right_trunc_marker = '',
    max_name_length = 30,
    max_prefix_length = 15,
    tab_size = 18,
    diagnostics = "nvim_lsp",      -- show LSP diagnostics in tab
    show_buffer_icons = true,       -- show filetype icons (important!)
    show_buffer_close_icons = true, -- show close icon for each buffer
    show_close_icon = false,        -- we only want per-buffer close icon
    show_tab_indicators = true,
    persist_buffer_sort = true,
    enforce_regular_tabs = false,
    always_show_bufferline = true,
    separator_style = "slant",      -- VS Code-like slant separators
    sort_by = 'id',
  },
})

-- Bufferline keymaps
vim.keymap.set('n', '<A-1>', ':BufferLineGoToBuffer 1<CR>')
vim.keymap.set('n', '<A-2>', ':BufferLineGoToBuffer 2<CR>')
vim.keymap.set('n', '<A-3>', ':BufferLineGoToBuffer 3<CR>')
vim.keymap.set('n', '<A-4>', ':BufferLineGoToBuffer 4<CR>')
vim.keymap.set('n', '<A-5>', ':BufferLineGoToBuffer 5<CR>')
vim.keymap.set('n', '<A-6>', ':BufferLineGoToBuffer 6<CR>')
vim.keymap.set('n', '<A-7>', ':BufferLineGoToBuffer 7<CR>')
vim.keymap.set('n', '<A-8>', ':BufferLineGoToBuffer 8<CR>')
vim.keymap.set('n', '<A-9>', ':BufferLineGoToBuffer 9<CR>')
vim.keymap.set('n', '<A-0>', ':BufferLineGoToBuffer -1<CR>')
vim.keymap.set('n', '<S-l>', ':BufferLineCycleNext<CR>')
vim.keymap.set('n', '<S-h>', ':BufferLineCyclePrev<CR>')

-- ===================================================================
-- Keymaps
-- ===================================================================
vim.keymap.set("n", "<Tab>", function() require("oil").open() end)
vim.keymap.set("n", "<C-j>", ":m .+1<CR>==", { silent = true })
vim.keymap.set("n", "<C-k>", ":m .-2<CR>==", { silent = true })
vim.keymap.set("v", "<C-j>", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "<C-k>", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("n", "<leader>h", ":noh<CR>", { silent = true })
vim.keymap.set("n", "<BS>", close_buffer)
vim.keymap.set("n", "<C-BS>", ":qa<CR>")
vim.keymap.set('n', '<C-h>', ':BufferLineCyclePrev<CR>')
vim.keymap.set('n', '<C-l>', ':BufferLineCycleNext<CR>')
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end)
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end)
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers() end)

-- ===================================================================
-- Auto-clean non-breaking spaces
-- ===================================================================
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.c,*.cpp,*.java,*.py",
  callback = function()
    vim.cmd([[%s/\%u00A0/ /ge]])
  end,
})

-- ===================================================================
-- Colorscheme Toggle
-- ===================================================================
local colorschemes = { "tokyonight", "kanagawa", "nightfox", "nord", "catppuccin" }
local current_scheme = 1

vim.keymap.set("n", "<leader>cs", function()
  current_scheme = current_scheme + 1
  if current_scheme > #colorschemes then current_scheme = 1 end
  vim.cmd("colorscheme " .. colorschemes[current_scheme])
  vim.notify("Colorscheme: " .. colorschemes[current_scheme])
end)

-- ===================================================================
-- Language-specific Colorschemes
-- ===================================================================
local language_colors = {
  java = "nightfox",
  python = "nord",
  c = "tokyonight",
  cpp = "kanagawa",
}

vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype
    if language_colors[ft] then
      vim.cmd("colorscheme " .. language_colors[ft])
    end
  end,
})

-- ===================================================================
-- F5 Compile & Run in toggleterm
-- ===================================================================
local Terminal = require("toggleterm.terminal").Terminal
local function run_in_toggleterm(cmd)
  local term = Terminal:new({ cmd = cmd, hidden = true, direction = "horizontal", close_on_exit = false })
  term:toggle()
end

local function create_out_folder()
  local file_dir = vim.fn.expand("%:p:h")
  vim.fn.mkdir(file_dir .. "/out", "p")
  return file_dir .. "/out"
end

-- Java
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    vim.keymap.set("n", "<F5>", function()
      vim.cmd("w")
      local out_dir = create_out_folder()
      local file_name = vim.fn.expand("%:t:r")
      local cmd = "javac -d " .. out_dir .. " " .. vim.fn.expand("%") .. " && java -cp " .. out_dir .. " " .. file_name
      run_in_toggleterm(cmd)
    end, { buffer = true, silent = true })
  end,
})

-- C / C++
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.keymap.set("n", "<F5>", function()
      vim.cmd("w")
      local out_dir = create_out_folder()
      local file_name = vim.fn.expand("%:t:r")
      local exe = out_dir .. "/" .. file_name
      local cmd = "gcc " .. vim.fn.expand("%") .. " -o " .. exe .. " && " .. exe
      run_in_toggleterm(cmd)
    end, { buffer = true, silent = true })
  end,
})

-- Python
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    vim.keymap.set("n", "<F5>", function()
      vim.cmd("w")
      local cmd = "python3 " .. vim.fn.expand("%")
      run_in_toggleterm(cmd)
    end, { buffer = true, silent = true })
  end,
})

vim.keymap.set("n", "<C-/>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")
