# Starting a New Jam

Steps to turn the template into a new game. See [TEMPLATE_GUIDE.md](TEMPLATE_GUIDE.md) for how everything works.

## Before the jam

- [ ] Everyone installs the **same** Godot version (standard build, not .NET) from godotengine.org
- [ ] Create the itch.io page early as a **Draft** (HTML project, 1280 × 720 embed, fullscreen button on)

## Day 1: copy the template

- [ ] Copy the template folder **without** `.git` and `.godot` (Godot rebuilds `.godot` on open)
- [ ] Rename the folder (snake_case, e.g. `tower_defense_jam`) and start a fresh git repo
- [ ] Open it in Godot and wait for the import to finish
- [ ] **Project Settings → Application → Config:** set **Name** (window title) and **Version** to `0.1`
- [ ] **Project → Export → Web:** set the export path to a builds folder **outside** the project, file name `index.html`
- [ ] Press F5: boot → title → game → pause → settings → controls → back to title all work

## Make it yours

- [ ] Build the game in `game/` (replace the placeholder `game.gd` content; keep the pause/settings/controls/end screen instances and their wiring)
- [ ] Add game actions to **Project Settings → Input Map**, then add a row per action to the Controls menu (guide section 5)
- [ ] Assign music on the title and game scenes (`Music` slot) and on the Win / Game Over screens (optional)
- [ ] Swap the UI sounds in `core/autoloads/audio.tscn` if the game's style needs different ones
- [ ] Connect real win/lose conditions: `MenuManager.open_menu(win_screen)` / `game_over_screen`
- [ ] Check `Settings.screen_shake` and `Settings.flashing` before any shake or flash effect
- [ ] If game speed makes no sense for this game, delete its settings row and remove it from the Focus Chain
- [ ] Update the title text, background and credits (`core/ui/credits.tscn`, Body text): names, roles, asset credits and licenses

## Before submitting

- [ ] Test the full flow with **keyboard, mouse and controller**
- [ ] Remapped keys and settings survive closing and reopening (and a page reload on web)
- [ ] Bump **Version** in Project Settings
- [ ] Export **release** (Export With Debug **unticked**) to `index.html` outside the project
- [ ] Zip the build folder's **contents**, upload to the itch draft, test in the browser:
  - [ ] Click to start → music plays
  - [ ] Quit is hidden, fullscreen works
  - [ ] Page Up / Page Down do nothing (release build)
- [ ] Publish and submit to the jam a day early; keep day 9 as a buffer
- [ ] Rate other entries during voting
