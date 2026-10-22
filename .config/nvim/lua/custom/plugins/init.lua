-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    "lervag/vimtex",
    lazy = false, -- we don't want to lazy load VimTeX
    -- tag = "v2.15", -- uncomment to pin to a specific release
    init = function()
      -- VimTeX configuration goes here, e.g.
      vim.g.vimtex_view_method = "zathura"
    end,
  },
  -- {
  -- 	"Vigemus/iron.nvim",
  -- 	ft = "python",
  -- 	event = "VeryLazy",
  -- 	config = function()
  -- 		local iron = require("iron.core")
  --
  -- 		iron.setup({
  -- 			config = {
  -- 				-- Whether a repl should be discarded or not
  -- 				scratch_repl = true,
  -- 				-- Your repl definitions come here
  -- 				repl_definition = {
  -- 					sh = {
  -- 						command = { "zsh" },
  -- 					},
  -- 					python = {
  -- 						command = { "ipython", "--no-autoindent" }, -- { "ipython", "--no-autoindent" } or { "python" }
  -- 						format = require("iron.fts.common").bracketed_paste_python,
  -- 					},
  -- 				},
  -- 				-- How the repl window will be displayed
  -- 				-- See below for more information
  -- 				repl_open_cmd = "horizontal botright 15 split",
  -- 			},
  -- 			-- Iron doesn't set keymaps by default anymore.
  -- 			-- You can set them here or manually add keymaps to the functions in iron.core
  -- 			keymaps = {
  -- 				send_motion = "<space>xc",
  -- 				visual_send = "<space>xv",
  -- 				send_file = "<space>xf",
  -- 				send_line = "<space>xl",
  -- 				send_paragraph = "<space>xp",
  -- 				send_until_cursor = "<space>xu",
  -- 				cr = "<space>x<cr>",
  -- 				interrupt = "<space>x<space>",
  -- 				exit = "<space>xq",
  -- 				clear = "<space>cl",
  -- 			},
  -- 			-- If the highlight is on, you can change how it looks
  -- 			-- For the available options, check nvim_set_hl
  -- 			highlight = {
  -- 				italic = true,
  -- 			},
  -- 			ignore_blank_lines = true, -- ignore blank lines when sending visual select lines
  -- 		})
  --
  -- 		-- iron also has a list of commands, see :h iron-commands for all available commands
  -- 		vim.keymap.set("n", "<space>rs", "<cmd>IronRepl<cr>")
  -- 		vim.keymap.set("n", "<space>rr", "<cmd>IronRestart<cr>")
  -- 		vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>")
  -- 		vim.keymap.set("n", "<space>rh", "<cmd>IronHide<cr>")
  -- 		vim.keymap.set("n", "<space>xx", function()
  -- 			vim.cmd.normal(" xciN")
  -- 			vim.cmd.normal("vaN")
  -- 			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<esc>", true, false, true), "n", true)
  -- 		end, { noremap = true, silent = true })
  -- 	end,
  -- },
  -- usando packer como gestor (puedes adaptarlo si usas otro)
  {
    "Vigemus/iron.nvim",
    config = function()
      local iron = require("iron.core")
      local view = require("iron.view")
      local common = require("iron.fts.common")

      iron.setup({
        config = {
          -- REPL efímero (se descarta al cerrarlo, opcional)
          scratch_repl = true,
          -- Definiciones de REPL por tipo de archivo
          repl_definition = {
            python = {
              command = { "ipython", "--no-autoindent" }, -- o simplemente "python3"
              format = common.bracketed_paste_python,
              block_dividers = { "# %%", "#%%" }, -- define que esas líneas separan celdas
            },
          },
          -- cómo se muestra la ventana del REPL
          repl_open_cmd = view.bottom(40), -- por ejemplo abrir abajo ocupando 40 filas
        },
        keymaps = {
          toggle_repl = "<leader>rr",
          send_motion = "<leader>sc", -- enviar selección según movimiento
          send_line = "<leader>sl",
          send_file = "<leader>sf",
          send_code_block = "<leader>sb", -- enviar bloque (entre divisores)
          send_code_block_and_move = "<leader>sn",
          -- otras acciones útiles:
          interrupt = "<leader>si",
          clear = "<leader>cl",
        },
      })
    end,
  },
  {
    "ThePrimeagen/vim-be-good",
    cmd = "VimBeGood",
  },
}
