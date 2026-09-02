-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://www.lazyvim.org/configuration/keymaps
-- Add any additional keymaps here

-- author standard (verbatim from his Omarchy nvim config): ;l is Esc, everywhere possible
vim.keymap.set("i", ";l", "<Esc>")
vim.keymap.set("c", ";l", "<Esc>")
vim.keymap.set("v", ";l", "<Esc>")
vim.keymap.set("n", ";l", "<Esc>")
vim.keymap.set("t", ";l", [[<C-\><C-n>]])

-- NOTE: the <Space>-leader bindings in plugins/molten.lua rely on LazyVim
-- setting mapleader = " ". If this config is ever rebased off LazyVim, set
-- vim.g.mapleader explicitly — bare nvim defaults to backslash (bug found
-- porting to the NixOS test config, 2026-08-24).
