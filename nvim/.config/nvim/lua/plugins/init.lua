return {
  -- Nord colorscheme
  {
    "shaunsingh/nord.nvim",
    priority = 1000,
    config = function()
      vim.g.nord_contrast = true
      vim.g.nord_borders = true
      vim.g.nord_italic = false
      require("nord").set()
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file explorer" },
    },
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          -- Fix for Neovim 0.10+ treesitter compatibility
          preview = {
            treesitter = false,  -- Disable treesitter in previewer
          },
        },
      })
      pcall(require("telescope").load_extension, "fzf")

      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "[F]ind [F]iles" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "[F]ind by [G]rep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "[F]ind [B]uffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "[F]ind [H]elp" })
      vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "[F]ind [D]iagnostics" })
      vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "[F]ind [S]ymbols (document)" })
      vim.keymap.set("n", "<leader>fw", builtin.lsp_workspace_symbols, { desc = "[F]ind [W]orkspace symbols" })
    end,
  },

  -- Treesitter (Neovim 0.10+ has built-in treesitter, plugin is for parser management)
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "json", "yaml", "markdown" },
        auto_install = true,
      })
    end,
  },

  -- LSP
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "hrsh7th/cmp-nvim-lsp",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Clangd for C++ - use new vim.lsp.config API
      vim.lsp.config("clangd", {
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
          "--offset-encoding=utf-16",
        },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = vim.fs.root(0, { ".clangd", "compile_commands.json", ".git" }),
        capabilities = capabilities,
      })

      -- Lua LS
      vim.lsp.config("lua_ls", {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_dir = vim.fs.root(0, { ".luarc.json", ".git" }),
        capabilities = capabilities,
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- Enable LSPs
      vim.lsp.enable("clangd")
      vim.lsp.enable("lua_ls")

      -- Suppress encoding warnings (functionality works despite warnings)
      local notify = vim.notify
      vim.notify = function(msg, ...)
        if msg:match("symbols_to_items") and msg:match("position encoding") then
          return
        end
        notify(msg, ...)
      end

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          map("gd", vim.lsp.buf.definition, "[G]oto [D]efinition")
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
          map("gr", vim.lsp.buf.references, "[G]oto [R]eferences")
          map("gI", vim.lsp.buf.implementation, "[G]oto [I]mplementation")
          map("K", vim.lsp.buf.hover, "Hover Documentation")
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
          map("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
          map("<leader>sh", vim.lsp.buf.signature_help, "[S]ignature [H]elp")

          -- C++ specific: Switch between header and source
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "clangd" then
            map("<leader>h", function()
              vim.lsp.buf_request(0, "textDocument/switchSourceHeader",
                vim.lsp.util.make_text_document_params(), function(err, result)
                  if err then
                    vim.notify("Error switching source/header: " .. err.message, vim.log.levels.ERROR)
                    return
                  end
                  if not result then
                    vim.notify("Corresponding file not found", vim.log.levels.WARN)
                    return
                  end
                  vim.cmd("edit " .. vim.uri_to_fname(result))
                end)
            end, "Switch [H]eader/Source")
          end
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = "menu,menuone,noinsert" },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-y>"] = cmp.mapping.confirm({ select = true }),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.confirm({ select = true })
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "[M]arkdown [P]review" },
    },
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "nord",
        },
      })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Comment
  {
    "numToStr/Comment.nvim",
    config = true,
  },

  -- Which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },
}
