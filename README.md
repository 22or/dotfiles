For an effective terminal setup, I recommend a terminal tiler. I use the tiling window manager that comes with Pop!_OS.

## Dependencies
* [fd](https://github.com/sharkdp/fd)
* [fzf](https://github.com/junegunn/fzf)
* [vim-plug](https://github.com/junegunn/vim-plug)
* [bat](https://github.com/sharkdp/bat) (optional)

## Installation
Run the interactive install script:
```bash
curl -fsSL https://...install.sh | bash
```

## .bashrc

### Shell prompt

Two-line prompt. Falls back to plain `user@host:path$` in terminals without color support.

<img width="840" height="46" alt="image" src="https://github.com/user-attachments/assets/5a5f5eca-4580-437a-853d-100ecfc57727" />


### `ff` — Project-wide content search

Interactive search over file contents in the current directory tree, powered by `grep` + `fzf`. Ignores `.git`, `node_modules`, `dist`, `build`, etc. and binary file types.

<img width="840" src="https://github.com/user-attachments/assets/b9cf0918-0e5d-4c41-a684-cb9cfca5bad0" />

### `run` — C++ runner for competitive programming

Compiles and runs a `.cpp` file with `-std=c++17 -O2`, then removes the temporary binary on exit, interrupt, or error.

```bash
run file.cpp [extra g++ flags]
```

## .vimrc

Plugins managed with [vim-plug](https://github.com/junegunn/vim-plug)

### [vim-lsp](https://github.com/prabirshrestha/vim-lsp) + [vim-lsp-settings](https://github.com/mattn/vim-lsp-settings) — LSP
* Provides error checking, syntax highlighting, hover tooltips, etc.
* I use [Bear](https://github.com/rizsotto/Bear) to generate a compilation database

### [vista.vim](https://github.com/liuchengxu/vista.vim) — symbol navigation
* Depends on vim-lsp
* ``<Leader>f`` opens a symbol selector window

### [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim) + [asyncomplete-lsp.vim](https://github.com/prabirshrestha/asyncomplete-lsp.vim) — autocomplete
* Depends on vim-lsp
* ``<Tab>`` and ``<S-Tab>`` to cycle through options

### [fzf.vim](https://github.com/junegunn/fzf.vim) — file navigation
* ``<C-p>`` opens a file selector window

### Other plugins
* [context.vim](https://github.com/wellle/context.vim) — make context lines (functions, if-statements, for-loops, etc.) stick to the top
* [vim-signature](https://github.com/kshenoy/vim-signature) — show signs for Vim marks
* [vim-operator-highlight](https://github.com/Valloric/vim-operator-highlight) — robust syntax highlighting for operators

### GTK File Chooser Support

On write, automatically logs the file in GTK's RecentManager so files edited in Vim appear in recent files across GTK apps (like the GNOME file chooser).

Checks for GTK presence and headlessness so it's safe to use over SSH.
