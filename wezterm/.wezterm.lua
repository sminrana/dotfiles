local wezterm = require("wezterm")
local config = wezterm.config_builder()

config.initial_rows = 40
config.initial_cols = 140

-- Start with Dawn theme so the rotator uses it as the default
-- config.color_scheme = "Tokyo Night"
config.color_scheme = 'Gruvbox Dark (Gogh)'

config.max_fps = 120
config.scrollback_lines = 3000
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.animation_fps = 1
config.check_for_updates = false

config.bold_brightens_ansi_colors = "No"
config.font = wezterm.font({ family = "Menlo"})
config.font_size = 15.0
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.prefer_egl = true
config.cell_width = 1.0
config.default_cursor_style = "BlinkingBar"
-- Transparency OFF (important)
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0
config.term = "xterm-256color"
config.hide_tab_bar_if_only_one_tab = true

config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = false
config.window_close_confirmation = 'NeverPrompt'
config.native_macos_fullscreen_mode = false
config.cursor_blink_rate = 0
config.enable_wayland = false
config.adjust_window_size_when_changing_font_size = false

-- Input latency tuning
config.send_composed_key_when_left_alt_is_pressed = true
config.use_dead_keys = false
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

config.inactive_pane_hsb = {
	saturation = 1.0,
	brightness = 1.0,
}

config.disable_default_key_bindings = true

local act = wezterm.action
config.keys = {

	-- follow tmux-friendly Command bindings
	{ key = "s", mods = "CMD", action = act.SendKey({ mods = "CTRL", key = "s" }) },
	{ key = "a", mods = "CMD", action = act.SendKey({ mods = "CTRL", key = "a" }) },

	-- tmux window/pane commands via prefix (Ctrl-A) + key
  { key = "t", mods = "CMD",       action = act.SendString("\x01c") }, -- Cmd-t -> Ctrl-A then c (new tmux window)
	{ key = "[", mods = "CMD", action = act.SendString("\x01p") }, -- Cmd-[ -> Ctrl-A p (prev window)
	{ key = "]", mods = "CMD", action = act.SendString("\x01n") }, -- Cmd-] -> Ctrl-A n (next window)
	{ key = "{", mods = "CMD|SHIFT", action = act.SendString("\x01p") }, -- Cmd-Shift-[ -> Ctrl-A p (prev window)
	{ key = "}", mods = "CMD|SHIFT", action = act.SendString("\x01n") }, -- Cmd-Shift-] -> Ctrl-A n (next window)
	{ key = ".", mods = "CMD", action = act.SendString("\x01o") }, -- Cmd-. -> Ctrl-A o (other pane)
	{ key = "g", mods = "CMD", action = act.SendString("\x01g") }, -- Cmd-g -> Ctrl-A g (sessionizer)
	{ key = "x", mods = "CMD|SHIFT", action = act.SendString("\x01X") }, -- Cmd-Shift-x -> Ctrl-A X (instant kill)

	{ key = "(", mods = "CMD|SHIFT", action = act.SendString("\x01(") }, -- Cmd+SHIFT-( -> Ctrl-A ( (prev session)
	{ key = ")", mods = "CMD|SHIFT", action = act.SendString("\x01)") }, -- Cmd+SHIFT-) -> Ctrl-A ) (next session)
	{ key = "n", mods = "CMD|SHIFT", action = act.SendString("\x01N") }, -- Cmd-Shift-n -> Ctrl-A N (popup new/switch session)

	-- Cmd-1..Cmd-9 -> Ctrl-A 1..9 (switch tmux windows)
	{ key = "1", mods = "CMD", action = act.SendString("\x011") },
	{ key = "2", mods = "CMD", action = act.SendString("\x012") },
	{ key = "3", mods = "CMD", action = act.SendString("\x013") },
	{ key = "4", mods = "CMD", action = act.SendString("\x014") },
	{ key = "5", mods = "CMD", action = act.SendString("\x015") },
	{ key = "6", mods = "CMD", action = act.SendString("\x016") },
	{ key = "7", mods = "CMD", action = act.SendString("\x017") },
	{ key = "8", mods = "CMD", action = act.SendString("\x018") },
	{ key = "9", mods = "CMD", action = act.SendString("\x019") },

	{ key = "f", mods = "CMD|SHIFT", action = wezterm.action.ToggleFullScreen },
	{ key = "q", mods = "CMD", action = wezterm.action.QuitApplication },
}

-- Make copy/paste easier
-- copy_on_select and selection_word_boundary are not valid on some wezterm versions;
-- use explicit mouse/key bindings below instead.

-- Add common copy/paste shortcuts (Cmd and Ctrl+Shift)
table.insert(config.keys, { key = "c", mods = "CMD", action = wezterm.action.CopyTo("Clipboard") })
table.insert(config.keys, { key = "v", mods = "CMD", action = wezterm.action.PasteFrom("Clipboard") })
table.insert(config.keys, { key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("Clipboard") })
table.insert(config.keys, { key = "V", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") })
table.insert(config.keys, {
  key = "=",
  mods = "CMD",
  action = act.IncreaseFontSize,
})

table.insert(config.keys, {
  key = "-",
  mods = "CMD",
  action = act.DecreaseFontSize,
})
table.insert(config.keys, {
  key = "0",
  mods = "CMD",
  action = act.ResetFontSize,
})

-- Copy selection to clipboard on mouse release
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = nil,
		action = wezterm.action.CopyTo("Clipboard"),
	},
}

-- start zsh and run the helper `t` from .zshrc, then exec an interactive zsh
config.default_prog = { "/bin/zsh", "-i", "-c", "t; exec zsh" }

-- and finally, return the configuration to wezterm
return config
