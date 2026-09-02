#!/usr/bin/env bash
# Claude Code, installed from Anthropic's own installer into ~/.local/bin.
#
# ~/.local/bin is already on PATH via home/.profile, so nothing here edits a
# shell file.

readonly CLAUDE_INSTALL_URL=https://claude.ai/install.sh
readonly CLAUDE_BIN="$HOME/.local/bin/claude"

if [[ -x $CLAUDE_BIN ]]; then
	info "claude already installed at $CLAUDE_BIN"
	success "Claude Code present: $("$CLAUDE_BIN" --version 2>/dev/null || echo unknown)"
	return 0
fi

claude_installer=$(mktemp)
if ! curl -fsSL --proto '=https' --tlsv1.2 -o "$claude_installer" -- "$CLAUDE_INSTALL_URL"; then
	rm -f "$claude_installer"
	error "Could not download $CLAUDE_INSTALL_URL"
	return 1
fi

# Piping a download straight into a shell means never seeing what arrived. This
# at least refuses anything that is not a script -- a captive-portal login page
# and a shell script are both 200 OK.
if [[ $(head -n1 -- "$claude_installer") != '#!'* ]]; then
	rm -f "$claude_installer"
	error "$CLAUDE_INSTALL_URL did not return a script — refusing to run it"
	return 1
fi

if ! run_logged "Running the Claude Code installer" bash -- "$claude_installer"; then
	rm -f "$claude_installer"
	error "The Claude Code installer failed"
	return 1
fi
rm -f "$claude_installer"

if [[ ! -x $CLAUDE_BIN ]]; then
	error "The installer completed but $CLAUDE_BIN is not there"
	return 1
fi
success "Installed Claude Code: $("$CLAUDE_BIN" --version 2>/dev/null || echo unknown)"
