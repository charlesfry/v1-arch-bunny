-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://www.lazyvim.org/configuration/general
-- Add any additional options here

-- Bunny: pinned python3 provider (CHOICES `python-pynvim`: 52.4 -> 12.0 ms per
-- .py open, and molten/Jupyter needs a provider with pynvim). The venv is created
-- by install.d/75-nvim-notebook.sh.
local nvim_py = vim.fn.expand("~/.venvs/neovim/bin/python")
if vim.uv.fs_stat(nvim_py) then
  vim.g.python3_host_prog = nvim_py
else
  -- Fail loudly: without the provider venv, molten/Jupyter — the gripe this
  -- editor exists to fix — is silently dead. Say so once.
  vim.schedule(function()
    vim.notify(
      "Bunny: ~/.venvs/neovim missing — python provider unpinned; molten/Jupyter will NOT work. See :checkhealth bunny",
      vim.log.levels.WARN
    )
  end)
end
