# recall

**Throwaway shell macros for the commands you keep retyping — gone the moment you close the terminal, unless you decide to keep them.**

You know the drill: you're debugging something, and you keep running the same four or five commands over and over, in the same order, with tiny tweaks each time. Writing a permanent alias feels like overkill for something you'll only need today. Typing it all out by hand, every single time, is tedious and error-prone.

`recall` sits in between. It lets you **record a sequence of commands once**, give it a name, and replay the whole thing by just typing that name — for the rest of your terminal session. Close the terminal, and it's like it never existed. No files left behind, no `.bashrc` clutter, nothing to clean up.

And if a temporary macro turns out to be a keeper? One prompt turns it permanent.

---

## Why

Most solutions to "I keep typing the same commands" fall into two camps:

- **Shell history tricks** (`!!`, `Ctrl+R`, `history | grep`) — fast, but they only replay *one* command at a time, and only ones you've already run.
- **Aliases / functions in `.bashrc`** — great for things you'll use forever, but heavyweight for a one-off task you'll never need again after today, and they pollute your shell config over time.

`recall` is the missing middle option: **session-scoped, multi-step, named macros**, with an easy upgrade path to permanent if you change your mind.

---

## Example

Say you're iterating on an Android build and keep running:

```bash
rm -f app-debug.apk
unzip -o build-output.zip
adb uninstall com.example.myapp
adb install app-debug.apk
```

With `recall`:

```bash
$ makecmd
Name this command set: redeploy
Enter commands one by one. Press Enter on empty line to finish.
Command 1: rm -f app-debug.apk
Command 2: unzip -o build-output.zip
Command 3: adb uninstall com.example.myapp
Command 4: adb install app-debug.apk
Command 5: 
Saved. Run 'redeploy' anytime this session to execute all 4 command(s).
Make this permanent too? (y/n): n
```

From now on, for the rest of this terminal session:

```bash
$ redeploy
```

...runs all four steps, in order, every time. Close the terminal and `redeploy` is gone — no trace, no cleanup needed.

---

## Installation

Clone the repo and source the script:

```bash
git clone https://github.com/yourusername/recall.git
source recall/recall.sh
```

That's it — no dependencies beyond `bash` (or `zsh`), which you already have.

> Sourcing only makes the functions (`makecmd`, `editcmd`, etc.) available in your *current* shell. Open a new terminal tab, and you'll need to `source` it again — that's by design. If you want these helper commands available everywhere, see [Making recall itself permanent](#making-recall-itself-permanent) below.

---

## Commands

| Command | What it does |
|---|---|
| `makecmd` | Prompts you for a name, then for commands one at a time (empty line to finish). Saves it as a callable function for this session. |
| `listcmds` | Lists all command sets currently saved in this session. |
| `editcmd` | Shows your saved sets, lets you pick one, then edit a line, add a line, delete a line, or rewrite the whole thing. |
| `savecmd` | Takes an existing temporary set and writes it permanently to a file of your choice (e.g. `~/.bashrc`), so it survives after this session ends. |
| `forgetcmds` | Walks through all saved sets and asks, one by one, whether to delete each. |

Every saved set becomes a plain shell function under the hood — so once you've created `redeploy`, just type `redeploy` to run it. No special syntax needed to *run* a set; only to create, edit, save, or delete one.

---

## Making a macro permanent

If a temporary macro turns out to be genuinely useful, you don't need to retype it anywhere. Either:

- Say `y` when `makecmd` or `editcmd` asks **"Make this permanent too?"**, or
- Run `savecmd` at any point afterward.

You'll be asked where to save it:

```
Where do you want to save 'redeploy'?
  1) /home/you/.bashrc (auto-loads in every new terminal)
  2) A custom file path
```

Choosing your `.bashrc`/`.zshrc` means it'll be available in every future terminal automatically — no different from any alias you'd hand-write yourself.

---

## Making recall itself permanent

`recall` follows the same "you decide" philosophy it offers for your own macros. If you want `makecmd`, `editcmd`, and friends available in every new terminal without manually sourcing the script each time, add this line to your `~/.bashrc` (or `~/.zshrc`):

```bash
source /path/to/recall/recall.sh
```

Replace `/path/to/recall` with wherever you cloned the repo.

---

## How it works (the short version)

Nothing is written to disk unless you explicitly ask for it via `savecmd`. While a macro is "temporary," it exists purely as:

1. A real shell function, defined dynamically via `eval` — same mechanism as if you'd typed the function definition yourself.
2. A copy of its raw command list in an in-memory associative array, so `editcmd` has something to show and modify.

Both live only inside your current shell process's memory. Closing the terminal kills that process, and the OS reclaims the memory — there's nothing to clean up because there was never a file to begin with.

---

## Compatibility

Written in portable `bash`. Tested on Fedora Linux with the [Kitty terminal](https://sw.kovidgoyal.net/kitty/), but works in any terminal emulator running `bash` or `zsh` — the terminal app itself is irrelevant; all the logic happens in the shell.

---

## Contributing

Issues and PRs welcome. This started as a small personal itch-scratcher, so there's plenty of room to grow — multi-shell parity (fish, etc.), tab-completion for set names, import/export of stashes between machines, and so on.
