# jenv setup (portable)
if [[ -d "$HOME/.jenv" ]]; then
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)"
fi

# OpenJDK paths
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS: Homebrew location
  [[ -d "/opt/homebrew/opt/openjdk@17/bin" ]] && export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
  [[ -d "/usr/local/opt/openjdk@17/bin" ]] && export PATH="/usr/local/opt/openjdk@17/bin:$PATH"
else
  # Linux: common locations
  [[ -d "/usr/lib/jvm/java-17-openjdk/bin" ]] && export PATH="/usr/lib/jvm/java-17-openjdk/bin:$PATH"
  [[ -d "/usr/lib/jvm/java-17-openjdk-amd64/bin" ]] && export PATH="/usr/lib/jvm/java-17-openjdk-amd64/bin:$PATH"
fi

