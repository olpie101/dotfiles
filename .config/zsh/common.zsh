# Debian/Ubuntu ship bat as `batcat` (the `bat` name belongs to
# bacula-console). `command -v bat` only finds executables, never aliases,
# so checking for `bat` alone can never succeed there even though the
# package IS installed — hence the explicit batcat branch.
if command -v bat &> /dev/null
then
    alias cat=bat
elif command -v batcat &> /dev/null
then
    alias cat=batcat
    alias bat=batcat
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
export GOOGLE_CLOUD_PROJECT=$GOOGLE_VERTEX_PROJECT
export GOOGLE_CLOUD_LOCATION=$GOOGLE_VERTEX_LOCATION

