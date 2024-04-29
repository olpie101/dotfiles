if command -v podman &> /dev/null
then
    alias docker=podman
else 
    echo "podman was not found"
fi

