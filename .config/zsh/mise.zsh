# mise (PATH activation for interactive shells)
# Shims alone only expose a tool's env (e.g. the per-version GOBIN that
# `go install` writes to) inside the shimmed process, so binaries installed
# there never land on PATH. Activation puts each tool's real bin dir on PATH
# and re-evaluates it per directory. Non-interactive contexts keep using shims.
command -v mise &> /dev/null && eval "$(mise activate zsh)"
