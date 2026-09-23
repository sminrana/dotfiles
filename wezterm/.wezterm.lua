local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Window Geometry
config.initial_rows = 40
config.initial_cols = 140

-- Theme: Harmonized with Neovim gruvbox
config.color_scheme = "Gruvbox Dark (Gogh)"

-- Performance & Rendering
config.max_fps = 120
config.animation_fps = 1
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.prefer_egl = true
config.scrollback_lines = 10000
config.check_for_updates = false

-- Font with Nerd Font Symbols Fallback (ensures LazyVim & p10k icons render)
config.font = wezterm.font_with_fallback({
  { family = "Menlo" },
  { family = "JetBrains Mono Nerd Font" },
  { family = "Symbols Nerd Font Mono" },
})
config.font_size = 15.0
config.cell_width = 1.0
config.bold_brightens_ansi_colors = "No"

-- Cursor & Look
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 0
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0
config.window_decorations = "RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.native_macos_fullscreen_mode = false
config.adjust_window_size_when_changing_font_size = false

config.window_padding = {
  left = 2,
  right = 2,
  top = 2,
  bottom = 2,
}

-- Minimal tab bar (tmux handles multiplexing tabs/windows)
config.enable_tab_bar = false
config.use_fancy_tab_bar = false
config.enable_scroll_bar = false

-- Latency tuning & Input
config.send_composed_key_when_left_alt_is_pressed = true
config.use_dead_keys = false

-- Keybindings: Native macOS Cmd shortcuts bridged to Tmux (Ctrl-A prefix)
config.disable_default_key_bindings = true
config.keys = {
  -- Core passthrough
  { key = "s", mods = "CMD", action = act.SendKey({ mods = "CTRL", key = "s" }) },
  { key = "a", mods = "CMD", action = act.SendKey({ mods = "CTRL", key = "a" }) },

  -- Tmux Window Management
  { key = "t", mods = "CMD", action = act.SendString("\x01c") }, -- Cmd-t -> New window (C-a c)
  { key = "w", mods = "CMD", action = act.SendString("\x01x") }, -- Cmd-w -> Close pane with prompt (C-a x)
  { key = "w", mods = "CMD|SHIFT", action = act.SendString("\x01X") }, -- Cmd-Shift-w -> Instant kill pane (C-a X)
  { key = "x", mods = "CMD|SHIFT", action = act.SendString("\x01X") }, -- Cmd-Shift-x -> Instant kill pane (C-a X)

  -- Window Switching
  { key = "[", mods = "CMD", action = act.SendString("\x01p") }, -- Cmd-[ -> Previous window (C-a p)
  { key = "]", mods = "CMD", action = act.SendString("\x01n") }, -- Cmd-] -> Next window (C-a n)
  { key = "{", mods = "CMD|SHIFT", action = act.SendString("\x01p") }, -- Cmd-Shift-[ -> Prev window
  { key = "}", mods = "CMD|SHIFT", action = act.SendString("\x01n") }, -- Cmd-Shift-] -> Next window

  -- Window Jump (Cmd-1..9)
  { key = "1", mods = "CMD", action = act.SendString("\x011") },
  { key = "2", mods = "CMD", action = act.SendString("\x012") },
  { key = "3", mods = "CMD", action = act.SendString("\x013") },
  { key = "4", mods = "CMD", action = act.SendString("\x014") },
  { key = "5", mods = "CMD", action = act.SendString("\x015") },
  { key = "6", mods = "CMD", action = act.SendString("\x016") },
  { key = "7", mods = "CMD", action = act.SendString("\x017") },
  { key = "8", mods = "CMD", action = act.SendString("\x018") },
  { key = "9", mods = "CMD", action = act.SendString("\x019") },

  -- Tmux Pane Splitting & Zooming
  { key = "d", mods = "CMD", action = act.SendString("\x01|") }, -- Cmd-d -> Split horizontal/right (C-a |)
  { key = "d", mods = "CMD|SHIFT", action = act.SendString("\x01_") }, -- Cmd-Shift-d -> Split vertical/down (C-a _)
  { key = "z", mods = "CMD", action = act.SendString("\x01z") }, -- Cmd-z -> Toggle pane zoom (C-a z)
  { key = ".", mods = "CMD", action = act.SendString("\x01o") }, -- Cmd-. -> Switch to other pane

  -- Sessionizer & Navigation Popups
  { key = "g", mods = "CMD|SHIFT", action = act.SendString("\x01g") }, -- Cmd-Shift-g -> Sessionizer popup (C-a g)
  { key = "n", mods = "CMD|SHIFT", action = act.SendString("\x01N") }, -- Cmd-Shift-n -> New session popup (C-a N)
  { key = "(", mods = "CMD|SHIFT", action = act.SendString("\x01(") }, -- Cmd-Shift-( -> Previous session
  { key = ")", mods = "CMD|SHIFT", action = act.SendString("\x01)") }, -- Cmd-Shift-) -> Next session

  -- Search / Copy Mode
  { key = "f", mods = "CMD", action = act.SendString("\x01[") }, -- Cmd-f -> Tmux search / copy mode
  { key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") }, -- Cmd-k -> Clear terminal

  -- Font Size & Fullscreen
  { key = "=", mods = "CMD", action = act.IncreaseFontSize },
  { key = "-", mods = "CMD", action = act.DecreaseFontSize },
  { key = "0", mods = "CMD", action = act.ResetFontSize },
  { key = "f", mods = "CMD|SHIFT", action = act.ToggleFullScreen },
  { key = "q", mods = "CMD", action = act.QuitApplication },

  -- System Clipboard Copy / Paste
  { key = "c", mods = "CMD", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CMD", action = act.PasteFrom("Clipboard") },
  { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
  { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
}

-- Copy selection to clipboard on mouse release
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = "Left" } },
    mods = "NONE",
    action = act.CopyTo("Clipboard"),
  },
}

-- Launch zsh and run the workspace helper `t`, falling back to zsh
config.default_prog = { "/bin/zsh", "-i", "-c", "t; exec zsh" }

return config
