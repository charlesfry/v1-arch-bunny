# Bunny Plymouth theme (parked)

Held out of the install while the boot splash is being matched byte-for-byte
against [viacoffee/dotfiles](https://github.com/viacoffee/dotfiles), whose `dot`
theme is known to work on this hardware. Nothing here is installed.

`install/default/plymouth/` currently holds his theme verbatim. To swap the
bunny back in once a real boot has been seen working:

1. Copy `bunny.plymouth` and `images/` over `install/default/plymouth/`,
   removing `dot.plymouth`, `images/dot.script` and `images/arch-logo.png`.
2. In `install/13-bootloader.sh`, change `PLYMOUTH_THEME` from `dot` to `bunny`.

`images/box.png`, `bullet.png`, `entry.png` and `lock.png` are not duplicated
here — they are Arch's stock example art and are byte-identical in both themes.

Two things this theme did that his does not, either of which may be why the
password dialog rendered once and never updated per keystroke. Re-introduce them
one at a time, not together:

- It registered no `Plymouth.SetRefreshFunction()`.
- It drew the username and an "Enter password to unlock" caption with
  `Image.Text`. The Plymouth initcpio hook resolves the initramfs font with
  `fc-match`, and neither theme sets `Font =` in its `.plymouth` file, so the
  font Plymouth gets is whatever is installed on the build machine — which at the
  time was `noto-fonts-emoji` and nothing else with Latin coverage.
