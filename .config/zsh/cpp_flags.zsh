# C/C++ compiler flags (macOS Homebrew only)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/opt/homebrew/opt/readline" ]]; then
  export LDFLAGS="-L/opt/homebrew/opt/readline/lib"
  export CPPFLAGS="-I/opt/homebrew/opt/readline/include"
elif [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/usr/local/opt/readline" ]]; then
  export LDFLAGS="-L/usr/local/opt/readline/lib"
  export CPPFLAGS="-I/usr/local/opt/readline/include"
fi

