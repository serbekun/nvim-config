-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function()
--     vim.cmd("botright term")
--   end
-- })

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

vim.opt.spell = true
vim.opt.spelllang = 'en'

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

-- ---------- plugins ----------
require("lazy").setup({

  -- 🎨 VSCode Theme
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("vscode").setup({
        transparent = false,
        italic_comments = true,
      })
      require("vscode").load()
    end,
  },

  {
    "mfussenegger/nvim-jdtls",
    -- Можно сделать lazy-load только для java-файлов
    ft = { "java" },
  },

  -- 🧩 Lualine status-bar
  { "nvim-lualine/lualine.nvim", config = true },

  -- 🌳 Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.config").setup({
        ensure_installed = { "c", "cpp", "python", "rust", "lua" },
        highlight = { enable = true },
        indent    = { enable = true },
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

  -- 🗂️ File tree
  { "nvim-tree/nvim-web-devicons" },
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
     keys = {
       { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "File tree" },
     },
     config = function()
      require("nvim-tree").setup({})
     end,
    },
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
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "buffer" },
    { name = "path" },
  }),
})

-- Setup Mason
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = { "clangd", "pyright", "rust_analyzer", "ltex" },
})

-- Capabilities for LSP
local capabilities = require("cmp_nvim_lsp").default_capabilities()

-- Global on_attach
local on_attach = function(client, bufnr)
  local bufmap = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
  bufmap("n", "gr", vim.lsp.buf.references, "List references")
  bufmap("n", "K", vim.lsp.buf.hover, "Hover documentation")
  bufmap("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
  bufmap("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
  bufmap("n", "<leader>fd", vim.lsp.buf.format, "Format document")
end

-- Setup LSP servers
vim.lsp.config("clangd", {
  capabilities = capabilities,
  on_attach = on_attach,
})

vim.lsp.config("pyright", {
  capabilities = capabilities,
  on_attach = on_attach,
})

vim.lsp.config("rust_analyzer", {
  capabilities = capabilities,
  on_attach = on_attach,
})

-- ── Java (jdtls) ────────────────────────────────────────────────────────────────
local jdtls_ok, jdtls = pcall(require, "jdtls")
if not jdtls_ok then
  print("nvim-jdtls not found — run :Lazy install mfussenegger/nvim-jdtls or :Lazy sync")
  return
end

local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

if vim.fn.executable(jdtls_bin) ~= 1 then
  print("jdtls binary not executable or missing → " .. jdtls_bin)
  print("Run :MasonInstall jdtls  (then restart Neovim)")
  return
end

-- Папка пакета jdtls (для glob и lombok)
local jdtls_package_dir = vim.fn.stdpath("data") .. "/mason/packages/jdtls"

-- Lombok (если файл не существует — lombok не установлен, убери строку -javaagent позже)
local lombok_jar = jdtls_package_dir .. "/lombok.jar"

-- Находим launcher JAR (самый свежий, версия меняется → glob обязателен!)
local launcher_jar = vim.fn.glob(jdtls_package_dir .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)[1]
if not launcher_jar or launcher_jar == "" then
  print("Equinox launcher JAR not found in " .. jdtls_package_dir .. "/plugins/")
  print("Reinstall jdtls: :MasonUninstall jdtls :MasonInstall jdtls")
  return
end

-- Configuration dir (для Linux — config_linux)
local config_dir = jdtls_package_dir .. "/config_linux"
if vim.fn.isdirectory(config_dir) ~= 1 then
  print("config_linux not found → probably wrong OS or broken install")
  return
end

-- Workspace — уникальный для каждого проекта (по имени папки проекта)
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

-- Команда запуска (самая стабильная версия)
local cmd = {
  "java",  -- или vim.fn.expand("$JAVA_HOME/bin/java") если JAVA_HOME настроен и нужен конкретный
  "-Declipse.application=org.eclipse.jdt.ls.core.id1",
  "-Dosgi.bundles.defaultStartLevel=4",
  "-Declipse.product=org.eclipse.jdt.ls.core.product",
  "-Dlog.level=ALL",
  "-Xms1g",
  "-Xmx2g",
  "--add-modules=ALL-SYSTEM",
  "--add-opens", "java.base/java.util=ALL-UNNAMED",
  "--add-opens", "java.base/java.lang=ALL-UNNAMED",
}

-- Lombok — добавляем только если файл существует
if vim.fn.filereadable(lombok_jar) == 1 then
  table.insert(cmd, "-javaagent:" .. lombok_jar)
end

-- Остальная часть cmd
table.insert(cmd, "-jar")
table.insert(cmd, launcher_jar)
table.insert(cmd, "-configuration")
table.insert(cmd, config_dir)
table.insert(cmd, "-data")
table.insert(cmd, workspace_dir)

local config = {
  cmd = cmd,
  root_dir = jdtls.setup.find_root({
    ".git",
    "mvnw", "gradlew",
    "pom.xml", "build.gradle", "build.gradle.kts",
    "settings.gradle", "settings.gradle.kts"
  }) or vim.fn.getcwd(),

  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = "fernflower" },  -- хороший декомпилятор
      completion = {
        favoriteStaticMembers = {
          "java.util.Objects.*",
          "java.lang.Math.*",
          "org.junit.jupiter.api.Assertions.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
    },
  },

  capabilities = require("cmp_nvim_lsp").default_capabilities(),
  on_attach = on_attach,  -- твой глобальный on_attach

  init_options = {
    bundles = {},  -- для java-test, java-debug добавь позже jars
  },
}

-- Автозапуск
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    require("jdtls").start_or_attach(config)
  end,
})
-- ---------- diagnostic and show errors ----------
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 2 },
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
})

local signs = { Error = "✘ ", Warn = "▲ ", Hint = "⚑ ", Info = " " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

vim.opt.backspace = { "indent", "eol", "start" }

-- ---------- Select All & Save ----------
vim.keymap.set("n", "<C-a>", "ggVG")
vim.keymap.set("i", "<C-a>", "<Esc>ggVG")
vim.keymap.set("v", "<C-a>", "<Esc>ggVG")

vim.keymap.set("n", "<C-s>", ":w<CR>")
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a")
vim.keymap.set("v", "<C-s>", "<Esc>:w<CR>")

vim.keymap.set("n", "<leader>dd", vim.diagnostic.open_float)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)

vim.keymap.set('n', '<A-Up>', ':m .-2<CR>==', { noremap = true, silent = true })
vim.keymap.set('n', '<A-Down>', ':m .+1<CR>==', { noremap = true, silent = true })
vim.keymap.set('i', '<A-Up>', '<Esc>:m .-2<CR>==gi', { noremap = true, silent = true })
vim.keymap.set('i', '<A-Down>', '<Esc>:m .+1<CR>==gi', { noremap = true, silent = true })
vim.keymap.set('v', '<A-Up>', ':m \'<-2<CR>gv=gv', { noremap = true, silent = true })
vim.keymap.set('v', '<A-Down>', ':m \'>+1<CR>gv=gv', { noremap = true, silent = true })
