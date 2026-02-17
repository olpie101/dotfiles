
# oh my zsh plugins
zstyle ':omz:plugins:keychain' agents gpg,ssh
zstyle ':omz:plugins:keychain' identities id_rsa github
zstyle ':omz:plugins:ssh-agent' identities id_rsa github
zstyle ':omz:plugins:nvm' lazy yes
zstyle ':omz:plugins:nvm' autoload yes
zstyle ':omz:plugins:nvm' silent-autoload yes
zstyle ':omz:plugins:nvm' lazy-cmd eslint prettier typescript
zstyle ':antidote:bundle' use-friendly-names 'yes'
# zstyle ':omz:plugins:ssh-agent' lazy yes
# zstyle ':omz:plugins:ssh-agent' quiet yes
#

ZSH_THEME=""
GIT_AUTO_FETCH_INTERVAL=600
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#ff00ff,bg=cyan,bold,underline"

export ZSH_CACHE_DIR="$HOME/.zsh-cache"

if [ ! -d "$ZSH_CACHE_DIR" ]; then
    echo "zsh cache dir not found. create: $ZSH_CACHE_DIR"
    mkdir -p $ZSH_CACHE_DIR
fi

if [ ! -d "$ZSH_CACHE_DIR/completions" ]; then
    echo "zsh completions dir not found. create: $ZSH_CACHE_DIR/completions"
    mkdir -p "$ZSH_CACHE_DIR/completions"
fi

FPATH="$ZSH_CACHE_DIR/completions":$FPATH
autoload -Uz compinit
compinit

# source antidote (portable)
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: Homebrew location
  if [[ -f "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ]]; then
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
  elif [[ -f "/usr/local/opt/antidote/share/antidote/antidote.zsh" ]]; then
    source /usr/local/opt/antidote/share/antidote/antidote.zsh
  fi
else
  # Linux: git clone install location or distro packages
  if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
  elif [[ -f "/usr/share/zsh-antidote/antidote.zsh" ]]; then
    source /usr/share/zsh-antidote/antidote.zsh
  fi
fi

# initialize plugins statically with ${ZDOTDIR:-~}/.zsh_plugins.txt
antidote load

