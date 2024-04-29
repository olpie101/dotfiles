zsh_sys_os=$(uname | tr '[:upper:]' '[:lower:]')
if [[ $zsh_sys_os = "*darwin*" ]]; then
    alias p64c="pbpaste | base64 | pbcopy"
    alias p64d="pbpaste | base64 -D"
    alias p64dc="pbpaste | base64 -D | pbcopy"
fi
