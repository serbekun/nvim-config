-- ===============================
-- 🌙 Neovim Config by Sergey ✨
-- ===============================

-- ---------- main setting ----------
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.wrap = false
vim.opt.cursorline = true
vim.opt.clipboard = "unnamedplus"
vim.g.mapleader = " "

-- ---------- hot key ----------
vim.keymap.set("n", "<leader>w", ":w<CR>")
vim.keymap.set("n", "<leader>q", ":q<CR>")
vim.keymap.set("n", "<leader>x", ":x<CR>")

-- ---------- install Lazy.nvim ----------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- ---------- plagins ----------
require("lazy").setup({
  -- 🌙 theme
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    config = function()
      vim.cmd("colorscheme tokyonight")
    end
  },

  -- 🧩 Lualine status-bar
  { "nvim-lualine/lualine.nvim", config = true },

  -- 🌳 Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "c", "cpp", "python", "rust", "lua" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end
  },

  -- 🔍 Telescope
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- 🧠 LSP, Mason, Completion
  { "williamboman/mason.nvim", config = true },
  { "williamboman/mason-lspconfig.nvim", config = true },
  { "neovim/nvim-lspconfig" },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
  { "hrsh7th/cmp-buffer" },
  { "hrsh7th/cmp-path" },
  { "L3MON4D3/LuaSnip" },

  -- 🗂️ file tree
  { "nvim-tree/nvim-web-devicons" },
  { "nvim-tree/nvim-tree.lua", config = true },
})

-- ---------- setting LSP + code Completion ----------
local cmp = require("cmp")

cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  }),
})

-- auto install lsp for need languages
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "clangd", "pyright", "rust_analyzer" },
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

local servers = { "clangd", "pyright", "rust_analyzer" }
for _, server in ipairs(servers) do
  vim.lsp.config[server] = {
    capabilities = capabilities,
  }
end

-- connect servers
for _, server in ipairs(servers) do
  vim.lsp.enable(server)
end

-- ---------- diagnostic and show errors ----------
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    spacing = 2,
  },
  signs = true,
  underline = true,
  update_in_insert = true,
})

local signs = { Error = "✘ ", Warn = "▲ ", Hint = "⚑ ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- ---------- LSP hot key ----------
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "gr", vim.lsp.buf.references, { desc = "Find all references" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Show documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })

-- ---------- autoformat ---------
-- vim.api.nvim_create_autocmd("BufWritePre", {
--    callback = function()
--    vim.lsp.buf.format({ async = false })
-- end,
-- })

-- ---------- hot key for file tree ----------
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "file tree" })

