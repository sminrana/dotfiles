-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Tokyo Night"
config.bold_brightens_ansi_colors = "BrightOnly"
config.font =
	wezterm.font({ family = "JetBrains Mono", weight = "Medium", harfbuzz_features = { "calt=0", "clig=0", "liga=0" } })
config.font_size = 16.0
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.front_end = "OpenGL"
config.cell_width = 0.9
config.freetype_load_flags = "NO_HINTING"
config.window_close_confirmation = "AlwaysPrompt"
config.default_cursor_style = "BlinkingBar"

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.95
config.window_decorations = "RESIZE"
config.use_fancy_tab_bar = true

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

local act = wezterm.action
config.keys = {
	{ mods = "CMD", key = "s", action = act.SendKey({ mods = "CTRL", key = "s" }) },
	{ key = "d", mods = "CMD|SHIFT", action = wezterm.action.SplitVertical },
	{ key = "d", mods = "CMD", action = wezterm.action.SplitHorizontal },
	{ key = "LeftArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CMD", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "w", mods = "CMD", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
	{
		key = "w",
		mods = "CMD",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{ key = "t", mods = "CMD|SHIFT", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
	{ key = "f", mods = "CMD|SHIFT", action = wezterm.action.ToggleFullScreen },
	{ key = "p", mods = "CMD|SHIFT", action = wezterm.action({ PaneSelect = { alphabet = "0123456789" } }) },
	{
		key = "LeftArrow",
		mods = "CMD|SHIFT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "DownArrow",
		mods = "CMD|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{
		key = "RightArrow",
		mods = "CMD|SHIFT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
}

-- and finally, return the configuration to wezterm
return config
