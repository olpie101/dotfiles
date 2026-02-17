if command -v bat &> /dev/null
then
    alias cat=bat
else 
    echo "bat was not found"
fi

if command -v fzf &> /dev/null
then
    # fuzzy find config
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
else 
    echo "fzf was not found"
fi

if command -v starship &> /dev/null
then
    eval "$(starship init zsh)"
else 
    echo "starship was not found"
fi

if command -v zoxide &> /dev/null
then
    eval "$(zoxide init zsh)"
    # alias cd=z
else 
    echo "zoxide was not found"
fi

export GOOGLE_VERTEX_LOCATION=global
export GOOGLE_VERTEX_PROJECT=ai-experiments-462607
