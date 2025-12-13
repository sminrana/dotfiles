
# tmux and alacritty
I used tmux and alacrity on my Mac. Other terminal configurations, such as Wezterm (my second favorite) and Ghostly, also work great on my Mac.

[Read My Blog](https://sminrana.com)

## Keybinding

### alacritty
I loved CMD + SHIFT to switch to full screen. The first key binding is CMD + s to send the terminal CRTL + s which is Save on Neovim. 

```
[keyboard]
bindings = [
  { key = "s", mods = "Command", chars = "\u0013" },
  { key = "f", mods = "Command|Shift", action = "ToggleSimpleFullscreen" },
]
```

### tmux 
```
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

bind-key C-w run-shell "~/.config/tmux/scripts/session-menu.sh"

# Screen splitting
bind 'N' new-window -c "#{pane_current_path}"
bind '_' split-window -c "#{pane_current_path}"
bind '|' split-window -h -c "#{pane_current_path}"
bind-key x kill-pane

# Pane resizing
bind -r h resize-pane -L 5
bind -r j resize-pane -D 5
bind -r k resize-pane -U 5
bind -r l resize-pane -R 5
```

![Screenshot 2025-05-28 at 10 00 00 AM](https://github.com/user-attachments/assets/019bad2a-12e4-4cbf-86ac-c1be55de3073)



### LazyVim 

I have been using Neovim for more than five years now, I am still learning. Neovim journey is not an easy one, but it can make you productive.
Take a look at my lazyvim keymap https://github.com/sminrana/dotfiles/blob/main/nvim/lua/config/keymaps.lua
which I use daily for  navigating files, loading snippets, notes, and source codes.
