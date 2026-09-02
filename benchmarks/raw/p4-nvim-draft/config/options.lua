-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://www.lazyvim.org/configuration/general
-- Add any additional options here

-- BunnE: pinned python3 provider (CHOICES `python-pynvim`: 52.4 -> 12.0 ms per
-- .py open, and molten/Jupyter needs a provider with pynvim). The venv is
-- created by the installer: uv venv ~/.venvs/neovim, with pynvim
-- jupyter_client ipykernel matplotlib pillow sympy + our pnglatex module,
-- kernel registered as `bunne`, and ~/.local/share/jupyter/runtime created
-- (molten writes there but never creates it — CHOICES `jupyter-in-neovim`).
local nvim_py = vim.fn.expand("~/.venvs/neovim/bin/python")
if vim.uv.fs_stat(nvim_py) then
  vim.g.python3_host_prog = nvim_py
else
  -- fail loudly (CLAUDE.md): without the provider venv, molten/Jupyter — the
  -- gripe this editor exists to fix — is silently dead. Say so once.
  vim.schedule(function()
    vim.notify(
      "BunnE: ~/.venvs/neovim missing — python provider unpinned; molten/Jupyter will NOT work. See :checkhealth bunne",
      vim.log.levels.WARN
    )
  end)
end
