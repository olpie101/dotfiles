export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Go installation path (Linux typically uses /usr/local/go)
if [[ "$OSTYPE" == "linux"* ]] && [[ -d "/usr/local/go/bin" ]]; then
  export PATH="$PATH:/usr/local/go/bin"
fi

