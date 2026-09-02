-- venv-selector ships in LazyVim's python extra (bound <leader>cv, ft=python
-- only). The 4.15 render test showed a real pyright-vs-kernel venv mismatch,
-- so selection is a requirement, not a nicety (CHOICES `editor`).
return {
  {
    "linux-cultist/venv-selector.nvim",
    -- global mapping so it also works from markdown notebooks
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
    -- built-in searches cover project-local .venv; add the uv-managed shared
    -- venvs under ~/.venvs ($FD is substituted by the plugin)
    opts = {
      search = {
        home_venvs = {
          command = "$FD 'bin/python$' ~/.venvs --no-ignore-vcs --full-path --color never",
        },
      },
    },
  },
}
