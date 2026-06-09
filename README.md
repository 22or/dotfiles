Personal vim and bash configs. For an effective terminal setup, I recommend a tiling window manager — I use the one that ships with Pop!_OS.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/22or/dotfiles/refs/heads/master/install.sh | bash
```

Or from an existing checkout:

```bash
~/dotfiles/install.sh
```

Set `DOTFILES_ROOT` before running to use a different checkout path. Re-run after pulling changes to refresh symlinks.

## Dependencies

Installed interactively by `install.sh` (decline any prompt to skip):

* [fzf](https://github.com/junegunn/fzf), [fd](https://github.com/sharkdp/fd) — shell search and navigation
* [vim-plug](https://github.com/junegunn/vim-plug) — vim plugin manager
* [bashmarks](https://github.com/huyng/bashmarks) — directory bookmarks (`s`/`g`/`p`/`d`/`l`)
* [vifm](https://vifm.info/) — terminal file manager

Installed automatically when the parent tool is present (no prompt):

* [bat](https://github.com/sharkdp/bat) — with fzf (`ff` previews) or vifm
* [chafa](https://hpjansson.org/chafa/), poppler-utils, mediainfo — with vifm (image/PDF/media previews)

## Layout

```
dotfiles/
├── install.sh       # tools → runtime deps → symlinks
├── uninstall.sh
├── lib/common.sh
├── .bashrc            # sourced from ~/.bashrc
├── .vimrc             # symlinked to ~/.vimrc
└── vifm/
```

| Config | Method | Target |
|--------|--------|--------|
| `.vimrc` | symlink | `~/.vimrc` |
| `.bashrc` | source line | `~/.bashrc` (not replaced) |
| `vifm/*` | symlink | `~/.config/vifm/`, `~/.local/bin/vifm-preview` |

Existing regular files at symlink targets are left untouched. Run `uninstall.sh` then `install.sh` for a clean reinstall.

## .bashrc

* Two-line prompt with job indicator (falls back to plain `user@host:path$` without color)
* **`ff`** — project-wide content search (`grep` + `fzf`, bat preview)
* **`run`** — compile and run a `.cpp` file (`-std=c++17 -O2`, cleans up binary on exit)
* fzf key bindings, bashmarks integration

## .vimrc

Plugins via [vim-plug](https://github.com/junegunn/vim-plug): LSP (vim-lsp + settings), autocomplete (asyncomplete), [fzf.vim](https://github.com/junegunn/fzf.vim) (`<C-p>`), [vista.vim](https://github.com/liuchengxu/vista.vim) (`<Leader>f`), context lines, marks, operator highlighting.

GTK RecentManager integration logs saved files to GNOME recents (skipped over SSH/headless).

## vifm

Vi-style dual-pane file manager. Config under `vifm/` — palenight theme, chafa image previews, bat text previews via `vifm-preview`.
