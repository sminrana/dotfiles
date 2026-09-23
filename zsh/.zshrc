# ==============================================================================
# Powerlevel10k Instant Prompt (must stay close to the top of ~/.zshrc)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# Deduplicated Path & Environment Setup
# ==============================================================================
typeset -U path PATH fpath FPATH

export LANG="en_US.UTF-8"
export PIP_REQUIRE_VIRTUALENV=true
export EDITOR="nvim"
export VISUAL="nvim"
export GPG_TTY=$(tty)

# Homebrew configuration (using local prefix)
export HOMEBREW_PREFIX="${HOME}/.local"
export HOMEBREW_CELLAR="${HOMEBREW_PREFIX}/Cellar"
export HOMEBREW_REPOSITORY="${HOMEBREW_PREFIX}/Homebrew"
export HOMEBREW_CASK_OPTS="${HOME}/Applications"

# Static tool paths (eliminates slow $(brew --prefix) subshell overhead)
export SSL_CERT_FILE="${HOMEBREW_PREFIX}/etc/ca-certificates/cert.pem"
export NODE_EXTRA_CA_CERTS="${HOME}/.local/etc/ssl/cert.pem"
export JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
export DOCKER_HOST="unix://${HOME}/.docker/run/docker.sock"
export RUBYOPT="-ropenssl"
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"

export ANDROID_HOME="${HOME}/Library/Android/sdk"
export ANDROID_SDK_ROOT="${ANDROID_HOME}"

# Deduplicated PATH entries (front-loaded in order of precedence)
path=(
  "${HOMEBREW_PREFIX}/bin"
  "${HOMEBREW_PREFIX}/sbin"
  "${HOME}/.local/bin"
  "${HOME}/.local/php/bin"
  "${HOMEBREW_PREFIX}/opt/node@22/bin"
  "${HOMEBREW_PREFIX}/opt/python@3.9/libexec/bin"
  "${HOMEBREW_PREFIX}/opt/mysql-client@8.4/bin"
  "${JAVA_HOME}/bin"
  "${HOME}/.cargo/bin"
  "${HOME}/.composer/vendor/bin"
  "${HOME}/.docker/bin"
  "${HOME}/.gem/bin"
  "${HOME}/.rbenv/shims"
  "${ANDROID_HOME}/emulator"
  "${ANDROID_HOME}/platform-tools"
  "${ANDROID_HOME}/tools"
  "${ANDROID_HOME}/tools/bin"
  "${HOME}/Library/Application Support/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin"
  $path
)

# Load Ruby gem path if available
if [ -d "${HOME}/.local/opt/ruby/bin" ]; then
  path=("${HOME}/.local/opt/ruby/bin" "${HOME}/.gem/ruby/3.4.0/bin" $path)
fi

# ==============================================================================
# Private Secrets & Machine-Local Overrides
# ==============================================================================
[[ -f "${HOME}/.config/zsh/.secrets" ]] && source "${HOME}/.config/zsh/.secrets"
[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"

# ==============================================================================
# Shell Options & History
# ==============================================================================
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY
HISTSIZE=10000
SAVEHIST=10000

# ==============================================================================
# Terminal Integration (WezTerm / OSC 7 Directory Reporting)
# ==============================================================================
# Informs WezTerm and Tmux of the exact current working directory
osc7_cwd() {
  local url_path=""
  local i ch hex
  for (( i = 0; i < ${#PWD}; i++ )); do
    ch="${PWD:$i:1}"
    case "$ch" in
      [a-zA-Z0-9.~_-]) url_path+="$ch" ;;
      *) printf -v hex "%%%02X" "'$ch"; url_path+="$hex" ;;
    esac
  done
  print -n "\e]7;file://${HOST}${url_path}\e\\"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd osc7_cwd
osc7_cwd 2>/dev/null

# Window title management (+ pomo timer when active)
precmd() {
  local ps
  ps=$(pomo-status 2>/dev/null)
  if [[ -n "$ps" ]]; then
    print -Pn "\e]0;%~ — $ps\a"
  else
    print -Pn "\e]0;%~\a"
  fi
}

preexec() {
  local ps
  ps=$(pomo-status 2>/dev/null)
  if [[ -n "$ps" ]]; then
    print -Pn "\e]0;%~ — $1 — $ps\a"
  else
    print -Pn "\e]0;%~ — $1\a"
  fi
}

# ==============================================================================
# Node & NVM
# ==============================================================================
export NVM_DIR="${HOME}/.nvm"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
[ -s "${NVM_DIR}/bash_completion" ] && \. "${NVM_DIR}/bash_completion"
export MKDP_NODE_PATH="$(command -v node 2>/dev/null)"

# ==============================================================================
# CLI Plugins: FZF, Atuin, Syntax Highlighting & Autosuggestions
# ==============================================================================
export FZF_DEFAULT_OPTS="--smart-case"
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

[[ -f "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "${HOMEBREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "${HOMEBREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ==============================================================================
# Aliases
# ==============================================================================
alias cl="clear"
alias kp="cd ~/work/kp"
alias logx="cd ~/work/logx"
alias mm="cd ~/work/mm/"
alias nc="cd ~/.config/nvim && nvim ."
alias notes="cd ~/Desktop/obs-v1/ && nvim ."
alias v="nvim"
alias vi="nvim"
alias vd="nvim -d"
alias y="yazi"
alias vf='nvim $(fzf)'
alias sshkey='ssh-keygen -t ed25519 -C "sminrana@gmail.com"'
alias mkd='cd ~/web/makocraft/mk-dealer/dealer && nvim . && take goals/daily.md'
alias create-laravel='composer create-project laravel/laravel example-app'
alias o="opencode"
alias g="gemini"
alias lzg="lazygit"
alias lzd="lazydocker"
alias gdnum="git diff --numstat"
alias nest="lsof -iTCP -sTCP:ESTABLISHED"
alias ni="netinfo"
alias ns="netsusp"
alias ssdc='docker compose -f .devcontainer/docker-compose.yml up -d \
  mariadb redis mailpit phpmyadmin \
  middleware-init middleware-php-fpm middleware-nginx \
  middleware-php-worker middleware-bulk-worker middleware-informal-entry-worker \
  admin-init admin-portal node-init customer-portal'

# Quick Tmux shortcuts
alias ta="tmux attach-session -t"
alias tls="tmux list-sessions"
alias tk="tmux kill-session -t"
alias tn="tmux new-session -s"

# ==============================================================================
# Productivity Functions
# ==============================================================================

# Fast config selector in Neovim
conf() {
  local target
  target=$(find "${HOME}/.config/nvim" "${HOME}/.config/tmux" "${HOME}/.config/wezterm" "${HOME}/.config/zsh" -type f 2>/dev/null | fzf --prompt="Edit config: ")
  [[ -n "$target" ]] && nvim "$target"
}

# Network Inspector
netinfo() {
  echo "==================== NETWORK INFO ===================="
  echo "🕒 Time: $(date)"
  echo "👤 User: $USER"
  echo "🖥  Host: $(scutil --get ComputerName 2>/dev/null) ($(hostname))"
  echo
  echo "-------------------- PUBLIC IP -----------------------"
  curl -s https://ifconfig.me || echo "No internet / blocked"
  echo
  echo "-------------------- DEFAULT ROUTE --------------------"
  route -n get default 2>/dev/null | awk '/gateway|interface/ {print}'
  echo
  echo "-------------------- DNS SERVERS ----------------------"
  scutil --dns | awk '/nameserver\[[0-9]+\]/{print $0}' | head -n 10
  echo
  echo "-------------------- ACTIVE INTERFACES ----------------"
  ifconfig | awk '
    /^[a-z0-9]+: / {iface=$1; sub(":", "", iface)}
    /status: active/ {print "✅ " iface " active"}
  '
  echo
  echo "-------------------- LOCAL IPs ------------------------"
  ipconfig getifaddr en0 2>/dev/null && echo " (en0 Wi-Fi)"
  ipconfig getifaddr en1 2>/dev/null && echo " (en1)"
  ipconfig getifaddr bridge0 2>/dev/null && echo " (bridge0)"
  echo
  echo "-------------------- LISTENING PORTS ------------------"
  lsof -nP -iTCP -sTCP:LISTEN | head -n 15
  echo "  (showing first 15)"
  echo
  echo "-------------------- ESTABLISHED (Top 25) -------------"
  lsof -nP -iTCP -sTCP:ESTABLISHED | head -n 25
  echo "  (showing first 25)"
  echo
  echo "-------------------- HTTPS (443) ----------------------"
  lsof -nP -iTCP:443 -sTCP:ESTABLISHED | head -n 25
  echo "  (showing first 25)"
  echo
  echo "======================================================="
}

netsusp() {
  echo "==== Suspicious / Non-local Established Connections ===="
  lsof -nP -iTCP -sTCP:ESTABLISHED \
    | grep -vE "127\.0\.0\.1|localhost|\[::1\]|\[fe80:" \
    | head -n 50
  echo "  (showing first 50)"
}

# Kill Docker processes safely
d1() {
  ps ax | grep -i docker | grep -ivE 'grep|com.docker.vmnetd' | awk '{print $1}' | xargs kill 2>/dev/null
}

# React Native reinstall helper
rn1() {
  rm -rf node_modules && npm i && rm -rf /iOS/Pods && npx pod-install
}

# Kill Node / NPM processes cleanly (macOS BSD compatible)
n1() {
  local pids
  pids=$(ps aux | grep -E 'node|npm' | grep -v grep | awk '{print $2}')
  if [[ -n "$pids" ]]; then
    echo "$pids" | xargs kill 2>/dev/null
    echo "✅ Terminated Node/NPM processes."
  else
    echo "No active Node/NPM processes found."
  fi
}

npm-packages() {
  echo "📦  Global npm packages:"
  npm list -g --depth=0 2>/dev/null || echo "No global packages found."
  echo ""
  echo "📦  Local npm packages (in current directory):"
  if [ -f package.json ]; then
    npm list --depth=0 2>/dev/null || echo "No local packages found."
  else
    echo "No package.json found — not a Node project directory."
  fi
}

npm-audit-all() {
  echo "🔍 Checking for vulnerabilities in global npm packages..."
  npm audit --global --json > /tmp/npm-audit-global.json 2>/dev/null
  if grep -q '"vulnerabilities":' /tmp/npm-audit-global.json; then
    npm audit --global
  else
    echo "✅ No known vulnerabilities in global packages."
  fi
  echo ""
  echo "🔍 Checking for vulnerabilities in local project..."
  if [ -f package.json ]; then
    npm audit || echo "⚠️  Unable to run audit — check if dependencies are installed."
  else
    echo "No package.json found — not a Node project directory."
  fi
}

l1() {
  php artisan view:clear && php artisan cache:clear && php artisan config:clear && php artisan route:clear && php artisan clear-compiled && composer dump-autoload
}

ju() {
  cd /Users/smin/ai/jupyter && source env/bin/activate && jupyter lab
}

dh() {
  cd /Users/smin/web/cloud/cloud && source env/bin/activate && cd dh
}

# Tmux Workspace Launcher (WezTerm default_prog target)
t() {
  local SESSION_NAME="${1:-WS-1}"
  local ROOT_DIR="${HOME}/Desktop/obs-v1"
  local YAZI_CMD="yazi"
  local NOTES_CMD="cd \"$ROOT_DIR\" && nvim ."

  if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    printf "📂 Creating workspace session: %s\n" "$SESSION_NAME"
    tmux new-session -d -s "$SESSION_NAME" -n yazi
    tmux new-window  -t "$SESSION_NAME" -n notes
    tmux send-keys -t "$SESSION_NAME:yazi" "$YAZI_CMD" C-m
    tmux send-keys -t "$SESSION_NAME:notes" "$NOTES_CMD" C-m
    tmux select-window -t "$SESSION_NAME:notes"
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$SESSION_NAME"
  else
    tmux attach-session -t "$SESSION_NAME"
  fi
}

# Kill unattached tmux sessions
t2() {
  tmux list-sessions -F '#{session_attached} #{session_id}' 2>/dev/null | \
    awk '/^0/{print $2}' | \
    xargs -n 1 tmux kill-session -t 2>/dev/null || echo "No unattached sessions to kill."
}

reload-zshrc() {
  echo "🔄 Reloading ~/.zshrc..."
  source ~/.zshrc
  echo "✅ ~/.zshrc reloaded."
}

gpg-keys() {
  gpg --list-secret-keys --keyid-format=long
}

# ==============================================================================
# Prompt Theme (Powerlevel10k)
# ==============================================================================
[[ -f "${HOME}/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "${HOME}/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "${HOME}/.p10k.zsh" ]] && source "${HOME}/.p10k.zsh"
