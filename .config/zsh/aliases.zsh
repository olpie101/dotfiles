zsh_sys_os=$(uname | tr '[:upper:]' '[:lower:]')

# macOS-specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias p64c="pbpaste | base64 | pbcopy"
    alias p64d="pbpaste | base64 -D"
    alias p64dc="pbpaste | base64 -D | pbcopy"
fi

# Linux-specific aliases
if [[ "$OSTYPE" == "linux"* ]]; then
    # bat is installed as batcat on Debian/Ubuntu
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        alias bat="batcat"
    fi
fi
