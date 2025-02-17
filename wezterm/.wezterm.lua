-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Tokyo Night"

config.font = wezterm.font("JetBrains Mono")
config.font_size = 16.0
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.front_end = 'OpenGL'
config.cell_width = 0.9
config.freetype_load_flags = 'FORCE_AUTOHINT'
config.window_close_confirmation = 'AlwaysPrompt'
config.default_cursor_style = 'BlinkingBar'

config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.98
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
}

-- and finally, return the configuration to wezterm
return config
