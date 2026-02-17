# Cross-platform paths
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="${HOME}/.local/bin:$PATH"
export PATH="${HOME}/.cargo/bin:$PATH"

# macOS Homebrew-specific paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  [[ -d "/opt/homebrew/opt/coreutils/libexec/gnubin" ]] && export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  [[ -d "/opt/homebrew/opt/arm-none-eabi-gcc@8/bin" ]] && export PATH="/opt/homebrew/opt/arm-none-eabi-gcc@8/bin:$PATH"
  [[ -d "/opt/homebrew/opt/avr-gcc@8/bin" ]] && export PATH="/opt/homebrew/opt/avr-gcc@8/bin:$PATH"
fi

