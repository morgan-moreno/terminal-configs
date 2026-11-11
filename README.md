# ~/.config

Configuration for Neovim, tmux, iTerm2 and 1Password. The repository root is
`~/.config` itself, and `.gitignore` is an allow-list, so other applications'
directories in `~/.config` are ignored.

## Set up on a new machine

`git clone` refuses to clone into a non-empty directory, and `~/.config`
usually already holds other applications' settings. Initialize the repository
in place instead, then check out the branch:

```bash
cd ~/.config
git init
git remote add origin <repository-url>
git fetch origin
git checkout -b main --track origin/main
```

The checkout writes only the tracked paths (`nvim/`, `tmux/`, `bootstrap/`, ...)
and leaves every other directory in `~/.config` untouched.

If a tracked file would overwrite an existing untracked file, git aborts the
checkout and lists the conflicting paths. Nothing is overwritten. Move those
files aside (for example `mv ~/.config/nvim ~/.config/nvim.bak`) and run the
`git checkout` command again.

## Install dependencies (Ubuntu)

See `bootstrap/` for scripts that install the pinned Neovim and tmux versions,
the JetBrainsMono Nerd Font, and the build and tool dependencies:

```bash
cd ~/.config/bootstrap
./install-deps.sh && ./install-neovim.sh && ./install-tmux.sh && ./install-font.sh
```
