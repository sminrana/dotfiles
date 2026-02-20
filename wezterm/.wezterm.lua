local wezterm = require("wezterm")
local config = wezterm.config_builder()

local mux = wezterm.mux
wezterm.on('gui-startup', function(window)
  local tab, pane, window = mux.spawn_window(cmd or {})
  local gui_window = window:gui_window();
  gui_window:perform_action(wezterm.action.ToggleFullScreen, pane)
end)


-- Start with Dawn theme so the rotator uses it as the default
-- config.color_scheme = "Tokyo Night"
config.color_scheme = 'tokyonight'

config.max_fps = 120
config.scrollback_lines = 3500
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.animation_fps = 60


config.bold_brightens_ansi_colors = "No"
config.font = wezterm.font({ family = "JetBrains Mono", weight = "Light" })
config.font_size = 16.0
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.front_end = "WebGpu"
config.webgpu_power_preference = "LowPower"
config.cell_width = 1.0
config.freetype_load_flags = "NO_HINTING"
config.default_cursor_style = "BlinkingBar"
-- Transparency OFF (important)
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0

config.hide_tab_bar_if_only_one_tab = true

config.window_decorations = "RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.use_fancy_tab_bar = false
config.window_close_confirmation = 'NeverPrompt'
config.native_macos_fullscreen_mode = true
config.cursor_blink_rate = 0



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
	saturation = 0.3,
	brightness = 0.3,
}

local act = wezterm.action
config.keys = {
	-- follow Alacritty tmux-friendly Command bindings
	{ mods = "CMD", key = "s", action = act.SendKey({ mods = "CTRL", key = "s" }) },
	{ key = "a", mods = "CMD", action = act.SendKey({ mods = "CTRL", key = "a" }) },

	-- tmux window/pane commands via prefix (Ctrl-A) + key
	{ key = "t", mods = "CMD", action = act.SendString("\x01c") }, -- Cmd-t -> Ctrl-A then c (new tmux window)
	{ key = "[", mods = "CMD", action = act.SendString("\x01p") }, -- Cmd-[ -> Ctrl-A p (prev window)
	{ key = "]", mods = "CMD", action = act.SendString("\x01n") }, -- Cmd-] -> Ctrl-A n (next window)
	{ key = ".", mods = "CMD", action = act.SendString("\x01o") }, -- Cmd-. -> Ctrl-A o (other pane)
	{ key = "x", mods = "CMD|SHIFT", action = act.SendString("\x01X") }, -- Cmd-Shift-x -> Ctrl-A X (instant kill)

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

	-- keep/manage panes and tabs shortcuts
	{ key = "d", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical },
	{ key = "d", mods = "CMD", action = wezterm.action.SplitHorizontal },
	{ key = "LeftArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{ key = "t", mods = "CMD|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "f", mods = "CMD|SHIFT", action = wezterm.action.ToggleFullScreen },
	{ key = "p", mods = "CMD|SHIFT", action = wezterm.action({ PaneSelect = { alphabet = "0123456789" } }) },
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },
}

-- start zsh and run the helper `t` from .zshrc, then exec an interactive zsh
config.default_prog = { "/bin/zsh", "-i", "-c", "t; exec zsh" }

-- and finally, return the configuration to wezterm
return config
