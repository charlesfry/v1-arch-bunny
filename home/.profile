# POSIX login environment. Read by greetd (source_profile = true) and by
# .bash_profile, so it must stay sh-compatible — no bashisms.

export EDITOR="nvim"
export VISUAL="$EDITOR"

# Suppress uwsm's console output during session start.
export UWSM_SILENT_START=1

# ~/.local/bin holds this repo's scripts and is where Claude Code installs.
# Arch does not add it to PATH.
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi
