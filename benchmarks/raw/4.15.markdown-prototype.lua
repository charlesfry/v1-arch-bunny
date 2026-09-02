-- throwaway port test (4.15): the dubrayn/nvim_dotfiles mechanisms, upstream-only
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {},
  },
  {
    "3rd/image.nvim",
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = { enabled = true, clear_in_insert_mode = false },
      },
    },
  },
  {
    "benlubas/molten-nvim",
    keys = {
      { "<S-Enter>", function()
          -- ignore_injections: the cursor sits in the injected python tree;
          -- the fence node lives in the outer markdown tree
          local node = vim.treesitter.get_node({ ignore_injections = true })
          while node and node:type() ~= "fenced_code_block" do
            node = node:parent()
          end
          if not node then
            return vim.notify("molten: no code fence under cursor", vim.log.levels.WARN)
          end
          for child in node:iter_children() do
            if child:type() == "code_fence_content" then
              local srow, _, erow, _ = child:range() -- 0-based, end-exclusive
              return vim.fn.MoltenEvaluateRange(srow + 1, erow)
            end
          end
        end, mode = "n", desc = "Evaluate markdown fence" },
      -- large outputs: enter the output window and scroll it like a buffer; q leaves.
      -- leader-based on purpose: kitty owns the Ctrl+Shift chords (C-S-h is its
      -- scrollback pager), so those never reach nvim.
      { "<leader>mi", "<cmd>MoltenInit<cr>", mode = "n", desc = "Init molten kernel (picker)" },
      { "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<cr>", mode = "n", desc = "Enter/scroll molten output" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", mode = "n", desc = "Hide molten output" },
      { "<leader>ms", "<cmd>MoltenShowOutput<cr>", mode = "n", desc = "Show molten output" },
    },
    init = function()
      vim.g.molten_output_virt_lines = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_output_win_max_height = 40
    end,
  },
}
