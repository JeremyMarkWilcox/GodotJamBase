# Jam Base — Template Guide

`godot_jam_base` is our pure-GDScript starting project for game jams. It gives every game working menus, settings, audio, controller support, key remapping and web export on day one, so jam time goes into the game itself.

- **Engine:** Godot 4.7.2, **standard** build (not .NET), from godotengine.org
- **Renderer:** Compatibility (required for web builds)
- **Base resolution:** 1280 × 720, stretch `canvas_items` / `expand`
- **Target:** web (itch.io) first, desktop second

See also: [NEW_JAM_CHECKLIST.md](NEW_JAM_CHECKLIST.md) for starting a new jam from this template.

---

## 1. Project layout

```
core/
  autoloads/   Global systems (see section 2)
  ui/          Reusable menus and their scripts, side by side
  theme/       Shared UI theme (base_theme.tres)
game/          THIS jam's content only (placeholder game scene lives here)
assets/        Shared raw media:
  fonts/         Font files plus their license (VT323 + OFL.txt)
  sounds/music/  Music tracks
  sounds/sfx/    Sound effects and UI sounds
docs/          These docs
addons/        Plugins, only when a project needs one
```

**Rule:** scripts live next to the scene they belong to (`pause_menu.tscn` + `pause_menu.gd`). There is no `scenes/` or `scripts/` folder. Reusable code goes in `core/`, game-specific code goes in `game/`.

## 2. Autoloads (globals)

Autoloads are nodes Godot creates once at startup and keeps alive across every scene. Call them from any script by name, e.g. `SceneManager.return_to_title()`.

They load **top to bottom in this order**, and the order matters (a later one may use an earlier one):

| Order | Name | File | Job |
| --- | --- | --- | --- |
| 1 | `Settings` | `core/autoloads/settings.gd` | Holds, applies and saves player settings |
| 2 | `InputManager` | `core/autoloads/input_manager.gd` | Keyboard vs controller detection, key remapping |
| 3 | `Audio` | `core/autoloads/audio.tscn` | UI sounds, sound effects, music |
| 4 | `SceneManager` | `core/autoloads/scene_manager.gd` | Fade transitions, restart, title, quit |
| 5 | `MenuManager` | `core/autoloads/menu_manager.gd` | Menu stack, Back, pausing, focus trap |
| 6 | `Debug` | `core/autoloads/debug.gd` | Debug-only shortcuts |

`Audio` is a **scene** autoload (`.tscn`) rather than a script, so its sound slots can be filled in the Inspector. Open `core/autoloads/audio.tscn` to change UI sounds.

Autoload scripts must **not** have a `class_name` (it would clash with the autoload name).

### SceneManager

| Call | What it does |
| --- | --- |
| `change_scene(path: String)` | Fade out, swap scene, fade in. Ignores calls while a transition is running |
| `restart()` | Reload the current scene |
| `return_to_title()` | Go to `TITLE_SCENE_PATH` (`res://core/ui/title.tscn`) |
| `quit()` | Close the game (does nothing on web) |
| `is_transitioning` | `true` during a fade |
| signals `transition_started`, `transition_finished` | Fired around every scene change |

Every scene change also unpauses the game, closes all menus and stops sound effects (music keeps playing and crossfades).

### MenuManager

| Call | What it does |
| --- | --- |
| `open_menu(menu: BaseMenu)` | Open a menu on top of the stack (the one underneath hides) |
| `close_menu()` | Close the top menu and return to the one below |
| `close_all()` | Close everything (done automatically on scene change) |
| `top_menu()` | The menu currently on top, or `null` |
| `is_menu_open()` | `true` if any menu is open |
| signals `menu_opened(menu)`, `menu_closed(menu)` | |

It also:

- Handles **Back**: `ui_cancel` (Esc / B) or `pause` closes the top menu, unless that menu has `can_go_back` off.
- **Pauses the game** while any open menu has `pauses_game` on.
- Runs the **focus trap**: if controller/keyboard focus ever leaves the top menu, it is pulled back. Players can never accidentally select buttons behind a menu.

### Settings

| Value | Setter | Notes |
| --- | --- | --- |
| `volumes["Master" / "Music" / "SFX" / "UI"]` | `set_volume(bus, 0.0–1.0)` | Controls the audio buses of the same name |
| `fullscreen` | `set_fullscreen(bool)` | Not auto-applied on web (browsers require a click) |
| `ui_scale` | `set_ui_scale(float)` | Scales all UI (0.75–1.25) |
| `screen_shake` | `set_screen_shake(bool)` | **Game code must check this** before shaking the camera |
| `flashing` | `set_flashing(bool)` | **Game code must check this** before flashing effects |
| `game_speed` | `set_game_speed(float)` | Sets `Engine.time_scale` (0.5–2) |

- `save_settings()` writes `user://settings.cfg`. The settings menu saves when it closes.
- Signal `changed` fires whenever any setting changes.

Example in game code:

```gdscript
if Settings.screen_shake:
	camera.shake(0.3)
```

### Audio

| Call | What it does |
| --- | --- |
| `play_sfx(stream, pitch_variation := 0.0)` | One-shot sound effect on the SFX bus (8 voices). `pitch_variation` of 0.1 makes repeats sound less robotic |
| `play_music(stream, fade_time := 1.0)` | Crossfade to a music track. Same track = ignored. `null` = fade out |
| `stop_music(fade_time)` | Fade music out |
| `stop_all_sfx()` | Stop every sound effect (called on scene change) |
| `play_ui(stream)` / `play_back()` | UI sounds (normally automatic) |

**Every button gets hover and click sounds automatically.** Audio watches for any button entering the game, so new menus need no sound wiring at all. The back sound plays when Esc/B closes a menu.

Music per scene: give the scene script `@export var music: AudioStream` and call `Audio.play_music(music)` in `_ready()`. The track keeps playing across scene changes until another scene asks for a different one.

### InputManager

| Call / value | What it does |
| --- | --- |
| `current_device` | `InputManager.Device.KEYBOARD_MOUSE` or `GAMEPAD` |
| signal `device_changed(device)` | Fires when the player switches (e.g. swap "Press Esc" hints to "Press Start") |
| `rebind(action, device, event)` | Change a binding (conflicts are swapped, never lost) |
| `reset_to_defaults()` | Restore the Project Settings Input Map |
| signal `bindings_changed` | Fires after any rebind or reset |

- **Every action you add to Project Settings → Input Map is remappable automatically**, except Godot's built-in `ui_*` actions.
- Remaps are saved to `user://controls.cfg`.
- Keyboard remaps use the **physical key position**, so they work on any keyboard layout.

### Debug

Active only in debug builds (the editor, or an export with **Export With Debug** ticked). Does nothing in release exports.

| Key | Action |
| --- | --- |
| F3 | Toggle FPS counter |
| Page Up | Emit `Debug.win_requested` |
| Page Down | Emit `Debug.lose_requested` |

The game scene decides what "win" and "lose" mean by connecting to those signals (see `game/game.gd`). F9–F11 are avoided because the editor uses them.

## 3. Scene flow

```
boot.tscn (main scene)
  └─ web: "Click to start" (unlocks browser audio)   desktop: skips straight on
title.tscn  ── Play ──►  game/game.tscn
  ├─ Settings ─► Controls                  ├─ Esc/Start ─► Pause menu
  ├─ Credits                               │     ├─ Resume / Restart / Quit to Title
  └─ Quit (hidden on web)                  │     └─ Settings ─► Controls
										   ├─ Win screen
										   └─ Game Over screen
```

- **Boot** is the main scene. To preview the click-to-start screen on desktop, tick **Always Show** on the `Boot` node (untick before committing).
- **Quit is hidden on web.** Browsers don't let a page close its own tab; calling quit just freezes the game on the itch page.
- The game auto-pauses when the window or tab loses focus (`Pause On Focus Loss` on the pause menu).

## 4. Menus: how they work

Every menu is a scene whose root script **extends `BaseMenu`** (`core/ui/base_menu.gd`).

### BaseMenu Inspector settings

| Setting | Meaning |
| --- | --- |
| **First Focus** | The control selected when the menu opens |
| **Pauses Game** | Pause gameplay while this menu is open (Pause, Win/Lose: on. Settings, Credits: off) |
| **Can Go Back** | Esc/B closes this menu (off for Win/Lose screens) |
| **Focus Chain** | The focusable controls in on-screen order. Controller/keyboard navigation follows this list and wraps around |
| **Focus Columns** | 1 = a vertical list. 2+ = a grid (left/right within a row, up/down between rows) |

Set these in the menu's **own `.tscn`**, not on its instances. Every instance picks them up.

The menu remembers where the player was: backing out of Settings returns focus to the Settings button, not the top of the list.

### The three layout rules (learned the hard way)

1. **A menu opened from another menu must be its sibling, not its child.** Opening a sub-menu hides the one underneath, and hiding a parent hides all its children.
2. **Never put a menu inside a Container** (VBox, HBox, Grid). Containers resize their children into rows and will squash the menu. Menus go *next to* containers.
3. **Only focusable controls go in the Focus Chain** (buttons, sliders, toggles), never labels or rows.

### Scrolling content (ScrollContainer)

For content taller than the screen (credits, long option lists), put it inside a **ScrollContainer**.

- **Give the ScrollContainer a Custom Minimum Size** (Inspector → Layout). Inside a VBox it otherwise shrinks to zero height and shows nothing.
- The content inside (e.g. a RichTextLabel) needs **Fit Content** on so it grows to its full height and the container has something to scroll.
- The Credits menu scrolls with the mouse wheel **and** with controller/keyboard up/down (`credits.gd`, `SCROLL_STEP` = pixels per press, hold to repeat).

### How to add a new menu

1. Create a scene: root **Control** (anchor preset Full Rect), attach a script that `extends BaseMenu`.
2. Add a **ColorRect** named `Dim` (Full Rect, black). Alpha 255 for full-screen pages, ~180–200 for overlays where the game should show through.
3. Add a **VBoxContainer** (anchor preset Center, Grow Direction **Both**) with your labels and buttons.
4. Script:

```gdscript
extends BaseMenu

@export var back_button: Button


func _ready() -> void:
	super()  # always call super() first: runs BaseMenu's setup
	back_button.pressed.connect(MenuManager.close_menu)
```

5. Fill in First Focus, Focus Chain and Pauses Game / Can Go Back.
6. Instance the menu in the scene that opens it, as a **sibling** of the other menus, and open it with `MenuManager.open_menu(the_menu)`.

### How to add a button to an existing menu

1. Add the Button inside the menu's VBox.
2. In the script: `@export var my_button: Button`, and in `_ready()` after `super()`: `my_button.pressed.connect(_on_my_button_pressed)`.
3. Drag the button into its new Inspector slot.
4. **Add it to the Focus Chain** in the right position. (Sounds are automatic.)

### Two controls in one row (e.g. the UI Scale − / + buttons)

Put only the **first** one in the Focus Chain, then link the pair in code after `super()`. See the end of `settings_menu.gd` for the pattern.

## 5. Key remapping

### How to add a new remappable action (e.g. `place_tower`)

1. **Project Settings → Input Map:** add the action with its default keyboard key and controller button. It is now remappable and saved automatically.
2. **`core/ui/controls_menu.tscn`:** in the GridContainer (3 columns) add a row, in order:
   - a **Label** with the action's display name
   - a **Button** with `core/ui/rebind.gd` attached, **Action** = `place_tower`, **Device** = Keyboard/Mouse
   - a **Button** with `rebind.gd`, **Action** = `place_tower`, **Device** = Controller
   - Give both buttons Custom Minimum Size X ≈ 160.
3. Add both buttons to the menu's **Focus Chain** as a pair (keyboard, then controller). Focus Columns stays 2.

### Behavior

- Click a binding, then press the new key/button.
- **Left-click** or controller **Back** cancels. Listening also times out after 5 seconds.
- Escape *can* be bound.
- If the new input is already used by another action, the two swap.
- **Reset to Defaults** restores the Input Map from Project Settings.

## 6. Adding a new setting

1. **`settings.gd`:** add a variable and a setter that applies it and emits `changed`; add a line to `save_settings()`, `load_settings()` and (if it needs applying at startup) `_apply_all()`.
2. **`settings_menu.tscn`:** add a row (Label + control) under the right section header.
3. **`settings_menu.gd`:** export the control, connect it to the setter in `_ready()`, and set it with `set_value_no_signal` / `set_pressed_no_signal` in `_sync_from_settings()`.
4. Add the control to the Focus Chain.

## 7. Win and Game Over

`core/ui/end_screen.tscn` is one reusable scene, instanced twice in the game scene (`WinScreen`, `GameOverScreen`).

| Setting | Meaning |
| --- | --- |
| Heading Text | "You Win!" / "Game Over" |
| Stinger | Short one-shot jingle played when the screen opens (optional) |
| Music | Track to crossfade to (optional; empty keeps the current music) |

From game code: `MenuManager.open_menu(game_over_screen)` when the player loses. Retry restarts the scene; Back to Title returns to the title.

## 8. Code conventions

Follow the official GDScript style guide:

| Thing | Style | Example |
| --- | --- | --- |
| Files and folders | snake_case | `wave_manager.gd`, `main_menu.tscn` |
| Classes, node names, autoloads | PascalCase | `BaseMenu`, `PlayButton`, `SceneManager` |
| Variables, functions, signals | snake_case | `move_speed`, `take_damage()`, `died` |
| Signals | past tense | `died`, `health_changed` |
| Constants, enum values | CONSTANT_CASE | `MAX_WAVES` |
| Private members | leading underscore | `_current_target` |
| Indentation | tabs | |

**snake_case file names matter for web builds:** web and Linux are case-sensitive, Windows isn't. A mismatched capital works in the editor and breaks in the browser.

**Rules:**

- **Static typing everywhere** (`var hp: int`, `func f(x: float) -> void`). Catches errors in the editor, improves autocomplete, and runs faster. The editor warns on untyped declarations.
- **`@export` instead of node paths.** Drag dependencies into Inspector slots; never hardcode `$Some/Path`.
- **Signals up, calls down.** Children emit signals ("I died"); parents and managers listen and call methods. Children never reach up to their parent.
- A system becomes an autoload only if it must survive scene changes or coordinate the whole game.
- Reusable `core/` code never contains game-specific names, art or mechanics.

### GDScript gotchas (especially coming from C#)

- **Indentation is structure.** A tab level is a `{ }` block. A `func` indented inside another function becomes a lambda and errors with *"Standalone lambdas cannot be accessed"* or *"Expected indented block after lambda declaration"*. Top-level `func` lines start at column 0.
- **`var` inside a function makes a new local variable.** Writing `var _music_tween = ...` inside a function hides the member `_music_tween` instead of assigning it. Assign without `var`.
- **Overriding `_ready()` in a script that extends another script:** call `super()` first, or the parent's setup never runs.
- **"Invalid access to property on a base object of type Nil"** almost always means an `@export` slot is empty in the Inspector.
- **Input order:** `_input` runs before the GUI; `_unhandled_input` runs after the GUI. Controls with Mouse Filter = Stop swallow clicks before `_unhandled_input` sees them.

## 9. Web export

- Use **Run in Browser** (Remote Deploy button, top right) for quick checks. It's always a debug build.
- For uploads: **Project → Export → Web → Export Project**, save as **`index.html`** in a folder **outside** the project, and **untick Export With Debug**.
- **Never export into the project folder.** The next export would pack the old build inside the new one.
- Zip the **contents** of the build folder (not the folder), upload to itch.io as an HTML project, embed size 1280 × 720, fullscreen button on.
- Double-clicking `index.html` does not work: browsers only load web games from a web server.

### Esc and fullscreen on web

Browsers reserve **Esc** for leaving fullscreen (ours or itch.io's button), and no game code can stop that. The template handles it like this:

- **Esc in fullscreen** exits fullscreen *and* opens Pause in one press (`game.gd` pauses when the web window shrinks).
- **The Fullscreen toggle** in Settings reads the browser's real state on web, so it shows off after an Esc.
- **Players who want to stay in fullscreen** can remap Pause in the Controls menu (e.g. to P or Tab). A controller's Start button pauses without leaving fullscreen.

For a jam game, tell players this on the itch.io page, e.g. *"Esc pauses but also exits fullscreen in the browser. Remap Pause in Settings → Controls to stay in fullscreen."*

## 10. UI theme

`core/theme/base_theme.tres` is set in **Project Settings → GUI → Theme → Custom**, so it styles every control in the game. Keep it a neutral baseline; each game restyles it for its own art direction.

- **Default Font / Default Font Size:** set on the theme resource itself.
- **Button styles:** Theme editor → Type: Button → StyleBoxes tab (`normal`, `hover`, `pressed`, `disabled`, `focus`). Use the same Content Margins on every state so buttons don't change size. Click a StyleBox slot to edit it in the Inspector.
- **Focus outline:** the `focus` StyleBox (Draw Center off, border 3px, bright border color). Also set it on HSlider and CheckButton. It only shows for keyboard/controller: MenuManager hides focus while the mouse is being used and brings it back on the first navigation press.
- **Section headers:** the `HeaderLabel` type variation (based on Label). Set a header node's **Theme Type Variation** to `HeaderLabel`.
- **Screen titles:** the `TitleLabel` type variation (bigger), used by menu titles such as "Credits".
- **Font:** VT323 lives in `assets/fonts/`. Swap it per game; keep the font's license file next to it and credit it.

**The Theme editor changes every control of the selected Type.** To style only some labels, use a type variation, not the Label type.

**Node settings beat the theme.** If a theme change doesn't show up on a node, check that node for a **Label Settings** resource (Labels) or ticked **Theme Overrides**; both replace the theme for that node.

## 11. Glossary

| Term | Meaning |
| --- | --- |
| **Autoload** | A global node Godot creates once at startup; reachable from any script by name |
| **Bus** | An audio channel (Master, Music, SFX, UI). Volume sliders control buses |
| **Amplify effect** | An effect added to a bus to balance a whole category's loudness. Use this instead of the bus fader, which Settings overwrites |
| **Crossfade** | Fading one music track out while the next fades in |
| **Stinger** | A short one-shot musical hit (1–5 s) marking a moment, like a victory fanfare. Plays over the music via the SFX pool |
| **Menu stack** | The list of open menus; only the top one is visible and receives input |
| **Focus** | Which control keyboard/controller input goes to (the highlighted button) |
| **Focus chain** | A menu's ordered list of focusable controls for navigation |
| **Focus trap** | MenuManager pulling focus back if it leaves the top menu |
| **Time scale** | `Engine.time_scale`; the game speed setting. Fades and crossfades ignore it |
| **Debug / release build** | Debug includes error checks and our debug keys; release is what players get |
| **Compatibility renderer** | Godot's renderer that works in browsers; required for web builds |
