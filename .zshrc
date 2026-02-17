# user configs
[[ -r /etc/zsh/zshrc.local ]] && source /etc/zsh/zshrc.local
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm (portable)
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# --- Gas Town Integration (managed by gt) ---
[[ -f "$HOME/.config/gastown/shell-hook.sh" ]] && source "$HOME/.config/gastown/shell-hook.sh"
# --- End Gas Town ---

# >>> conda initialize (portable) >>>
# Detect conda location based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: Homebrew location (ARM or Intel)
  if [[ -f "/opt/homebrew/Caskroom/miniconda/base/bin/conda" ]]; then
    CONDA_BASE="/opt/homebrew/Caskroom/miniconda/base"
  elif [[ -f "/usr/local/Caskroom/miniconda/base/bin/conda" ]]; then
    CONDA_BASE="/usr/local/Caskroom/miniconda/base"
  fi
else
  # Linux: common locations
  if [[ -f "$HOME/miniconda3/bin/conda" ]]; then
    CONDA_BASE="$HOME/miniconda3"
  elif [[ -f "$HOME/anaconda3/bin/conda" ]]; then
    CONDA_BASE="$HOME/anaconda3"
  elif [[ -f "/opt/conda/bin/conda" ]]; then
    CONDA_BASE="/opt/conda"
  fi
fi

if [[ -n "$CONDA_BASE" ]]; then
  __conda_setup="$("$CONDA_BASE/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
      . "$CONDA_BASE/etc/profile.d/conda.sh"
    else
      export PATH="$CONDA_BASE/bin:$PATH"
    fi
  fi
  unset __conda_setup
fi
unset CONDA_BASE
# <<< conda initialize <<<

# opencode (portable)
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"

