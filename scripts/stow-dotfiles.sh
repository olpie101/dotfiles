#!/usr/bin/env bash
#
# stow-dotfiles.sh - Symlink dotfiles using GNU Stow based on config
#
# Usage:
#   ./scripts/stow-dotfiles.sh [options] [package...]
#
# Options:
#   -n, --dry-run     Show what would be done without making changes
#   -a, --adopt       Adopt existing files (convert to symlinks)
#   -d, --delete      Remove symlinks (unstow)
#   -l, --list        List available packages
#   -f, --force       Force stow even if conflicts exist (use with caution)
#   -h, --help        Show this help message
#
# Examples:
#   ./scripts/stow-dotfiles.sh              # Stow all packages for current platform
#   ./scripts/stow-dotfiles.sh nvim claude  # Stow specific packages
#   ./scripts/stow-dotfiles.sh -n           # Dry run all packages
#   ./scripts/stow-dotfiles.sh -a claude    # Adopt existing claude config
#   ./scripts/stow-dotfiles.sh -d nvim      # Remove nvim symlinks

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory and dotfiles root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="$DOTFILES_DIR/stow-config.json"

# Detect platform
detect_platform() {
  case "$OSTYPE" in
    darwin*)  echo "darwin" ;;
    linux*)   echo "linux" ;;
    msys*|cygwin*|mingw*) echo "windows" ;;
    *)        echo "unknown" ;;
  esac
}

PLATFORM=$(detect_platform)

# Check dependencies
check_deps() {
  local missing=()
  
  if ! command -v stow &> /dev/null; then
    missing+=("stow")
  fi
  
  if ! command -v jq &> /dev/null; then
    missing+=("jq")
  fi
  
  if [[ ${#missing[@]} -gt 0 ]]; then
    echo -e "${RED}Error: Missing required dependencies: ${missing[*]}${NC}"
    echo ""
    echo "Install them with:"
    if [[ "$PLATFORM" == "darwin" ]]; then
      echo "  brew install ${missing[*]}"
    elif [[ "$PLATFORM" == "linux" ]]; then
      echo "  sudo apt install ${missing[*]}  # Debian/Ubuntu"
      echo "  sudo dnf install ${missing[*]}  # Fedora"
    fi
    exit 1
  fi
}

# Print usage
usage() {
  head -30 "$0" | grep -E "^#" | sed 's/^# \?//'
}

# List available packages
list_packages() {
  echo -e "${CYAN}Available packages:${NC}"
  echo ""
  
  jq -r --arg platform "$PLATFORM" '
    .packages[] | 
    select(.platforms | index($platform)) |
    "  \(.name)\t\(.description // "")"
  ' "$CONFIG_FILE" | column -t -s $'\t'
  
  echo ""
  echo -e "${YELLOW}Platform-specific packages (not available on $PLATFORM):${NC}"
  jq -r --arg platform "$PLATFORM" '
    .packages[] | 
    select(.platforms | index($platform) | not) |
    "  \(.name)\t[\(.platforms | join(", "))]\t\(.description // "")"
  ' "$CONFIG_FILE" | column -t -s $'\t'
}

# Expand ~ in paths
expand_path() {
  local path="$1"
  echo "${path/#\~/$HOME}"
}

# Get packages for current platform
get_platform_packages() {
  jq -r --arg platform "$PLATFORM" '
    .packages[] | 
    select(.platforms | index($platform)) |
    .name
  ' "$CONFIG_FILE"
}

# Get package config by name
get_package() {
  local name="$1"
  jq --arg name "$name" '.packages[] | select(.name == $name)' "$CONFIG_FILE"
}

# Check if package exists
package_exists() {
  local name="$1"
  jq -e --arg name "$name" '.packages[] | select(.name == $name)' "$CONFIG_FILE" > /dev/null 2>&1
}

# Check if package is available on current platform
package_available() {
  local name="$1"
  jq -e --arg name "$name" --arg platform "$PLATFORM" '
    .packages[] | 
    select(.name == $name) |
    select(.platforms | index($platform))
  ' "$CONFIG_FILE" > /dev/null 2>&1
}

# Stow a single package
stow_package() {
  local pkg_name="$1"
  local action="${2:-stow}"  # stow, unstow, or restow
  local dry_run="${3:-false}"
  local adopt="${4:-false}"
  local force="${5:-false}"
  
  if ! package_exists "$pkg_name"; then
    echo -e "${RED}Error: Package '$pkg_name' not found in config${NC}"
    return 1
  fi
  
  if ! package_available "$pkg_name"; then
    echo -e "${YELLOW}Skipping '$pkg_name': not available on $PLATFORM${NC}"
    return 0
  fi
  
  local pkg=$(get_package "$pkg_name")
  local source=$(echo "$pkg" | jq -r '.source')
  local target=$(echo "$pkg" | jq -r '.target')
  local files=$(echo "$pkg" | jq -r '.files // empty | .[]' 2>/dev/null)
  local description=$(echo "$pkg" | jq -r '.description // ""')
  
  # Expand paths
  target=$(expand_path "$target")
  local source_path
  if [[ "$source" == "." ]]; then
    source_path="$DOTFILES_DIR"
  else
    source_path="$DOTFILES_DIR/$source"
  fi
  
  # Verify source exists
  if [[ ! -e "$source_path" ]]; then
    echo -e "${RED}Error: Source '$source_path' does not exist${NC}"
    return 1
  fi
  
  # Build stow command
  local stow_cmd=("stow")
  
  # Action flags
  case "$action" in
    unstow)  stow_cmd+=("-D") ;;
    restow)  stow_cmd+=("-R") ;;
  esac
  
  # Options
  [[ "$dry_run" == "true" ]] && stow_cmd+=("-n")
  [[ "$adopt" == "true" ]] && stow_cmd+=("--adopt")
  stow_cmd+=("-v")
  
  # If specific files are listed, we need a different approach
  if [[ -n "$files" ]]; then
    # For specific files, create symlinks directly
    echo -e "${BLUE}[$pkg_name]${NC} $description"
    
    for file in $files; do
      local src="$source_path/$file"
      local dst="$target/$file"
      
      if [[ ! -e "$src" ]]; then
        echo -e "  ${YELLOW}Skip: $file (source not found)${NC}"
        continue
      fi
      
      if [[ "$action" == "unstow" ]]; then
        if [[ -L "$dst" ]]; then
          if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${CYAN}Would remove: $dst${NC}"
          else
            rm "$dst"
            echo -e "  ${GREEN}Removed: $dst${NC}"
          fi
        fi
      else
        # Ensure target directory exists
        mkdir -p "$(dirname "$dst")"
        
        if [[ -L "$dst" ]]; then
          local current_target=$(readlink "$dst")
          if [[ "$current_target" == "$src" ]] || [[ "$(cd "$(dirname "$dst")" && readlink -f "$file" 2>/dev/null)" == "$src" ]]; then
            echo -e "  ${GREEN}Already linked: $file${NC}"
            continue
          fi
        fi
        
        if [[ -e "$dst" && ! -L "$dst" ]]; then
          if [[ "$adopt" == "true" ]]; then
            if [[ "$dry_run" == "true" ]]; then
              echo -e "  ${CYAN}Would adopt: $file${NC}"
            else
              mv "$dst" "$src"
              ln -s "$src" "$dst"
              echo -e "  ${GREEN}Adopted: $file${NC}"
            fi
          elif [[ "$force" == "true" ]]; then
            if [[ "$dry_run" == "true" ]]; then
              echo -e "  ${CYAN}Would replace: $file${NC}"
            else
              rm -rf "$dst"
              ln -s "$src" "$dst"
              echo -e "  ${GREEN}Replaced: $file${NC}"
            fi
          else
            echo -e "  ${YELLOW}Conflict: $dst exists (use --adopt or --force)${NC}"
          fi
        else
          if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${CYAN}Would link: $file -> $src${NC}"
          else
            [[ -L "$dst" ]] && rm "$dst"
            ln -s "$src" "$dst"
            echo -e "  ${GREEN}Linked: $file${NC}"
          fi
        fi
      fi
    done
  else
    # Use stow for directory packages
    echo -e "${BLUE}[$pkg_name]${NC} $description"
    
    # Ensure target parent directory exists
    mkdir -p "$(dirname "$target")"
    
    # Calculate relative path for stow
    local rel_source
    if [[ "$source" == "." ]]; then
      # Stowing from root - use standard stow
      stow_cmd+=("-d" "$DOTFILES_DIR" "-t" "$target")
      
      # Get list of items to stow (exclude what's in exclude_always)
      local excludes=$(jq -r '.exclude_always[]' "$CONFIG_FILE" | tr '\n' '|' | sed 's/|$//')
      
      if [[ "$dry_run" == "true" ]]; then
        echo -e "  ${CYAN}Would stow dotfiles root to $target${NC}"
      else
        # For root stow, we handle each dotfile individually
        for item in "$DOTFILES_DIR"/.*; do
          local basename=$(basename "$item")
          [[ "$basename" =~ ^\.\.?$ ]] && continue
          [[ "$basename" =~ ^($excludes)$ ]] && continue
          [[ ! -e "$item" ]] && continue
          
          local dst="$target/$basename"
          if [[ -L "$dst" ]]; then
            echo -e "  ${GREEN}Already linked: $basename${NC}"
          elif [[ -e "$dst" ]]; then
            if [[ "$adopt" == "true" ]]; then
              echo -e "  ${YELLOW}Conflict: $basename (would need manual adoption)${NC}"
            else
              echo -e "  ${YELLOW}Conflict: $basename exists${NC}"
            fi
          else
            ln -s "$item" "$dst"
            echo -e "  ${GREEN}Linked: $basename${NC}"
          fi
        done
      fi
    else
      # Stowing a subdirectory
      if [[ -L "$target" ]]; then
        local current=$(readlink "$target")
        if [[ "$current" == "$source_path" ]] || [[ "$(readlink -f "$target" 2>/dev/null)" == "$source_path" ]]; then
          echo -e "  ${GREEN}Already linked${NC}"
          return 0
        fi
      fi
      
      if [[ -d "$target" && ! -L "$target" ]]; then
        if [[ "$adopt" == "true" ]]; then
          if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${CYAN}Would adopt existing directory${NC}"
          else
            # Merge: move contents to source, then link
            echo -e "  ${YELLOW}Adopting existing directory...${NC}"
            rsync -av "$target/" "$source_path/"
            rm -rf "$target"
            ln -s "$source_path" "$target"
            echo -e "  ${GREEN}Adopted and linked${NC}"
          fi
        else
          echo -e "  ${YELLOW}Conflict: $target exists as directory (use --adopt)${NC}"
        fi
      elif [[ -e "$target" && ! -L "$target" ]]; then
        echo -e "  ${YELLOW}Conflict: $target exists as file${NC}"
      else
        if [[ "$action" == "unstow" ]]; then
          if [[ -L "$target" ]]; then
            if [[ "$dry_run" == "true" ]]; then
              echo -e "  ${CYAN}Would remove link: $target${NC}"
            else
              rm "$target"
              echo -e "  ${GREEN}Removed link${NC}"
            fi
          fi
        else
          if [[ "$dry_run" == "true" ]]; then
            echo -e "  ${CYAN}Would link: $target -> $source_path${NC}"
          else
            [[ -L "$target" ]] && rm "$target"
            ln -s "$source_path" "$target"
            echo -e "  ${GREEN}Linked${NC}"
          fi
        fi
      fi
    fi
  fi
}

# Main
main() {
  local dry_run=false
  local adopt=false
  local delete=false
  local force=false
  local list=false
  local packages=()
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        dry_run=true
        shift
        ;;
      -a|--adopt)
        adopt=true
        shift
        ;;
      -d|--delete)
        delete=true
        shift
        ;;
      -f|--force)
        force=true
        shift
        ;;
      -l|--list)
        list=true
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      -*)
        echo -e "${RED}Unknown option: $1${NC}"
        usage
        exit 1
        ;;
      *)
        packages+=("$1")
        shift
        ;;
    esac
  done
  
  # Check dependencies
  check_deps
  
  # Check config file exists
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}"
    exit 1
  fi
  
  # List packages if requested
  if [[ "$list" == "true" ]]; then
    list_packages
    exit 0
  fi
  
  echo -e "${CYAN}Dotfiles Stow Manager${NC}"
  echo -e "Platform: ${GREEN}$PLATFORM${NC}"
  echo -e "Dotfiles: ${BLUE}$DOTFILES_DIR${NC}"
  echo ""
  
  if [[ "$dry_run" == "true" ]]; then
    echo -e "${YELLOW}DRY RUN - No changes will be made${NC}"
    echo ""
  fi
  
  # Determine action
  local action="stow"
  [[ "$delete" == "true" ]] && action="unstow"
  
  # Get packages to process
  if [[ ${#packages[@]} -eq 0 ]]; then
    # Process all platform-appropriate packages
    while IFS= read -r pkg; do
      packages+=("$pkg")
    done < <(get_platform_packages)
  fi
  
  # Process each package
  local success=0
  local failed=0
  
  for pkg in "${packages[@]}"; do
    if stow_package "$pkg" "$action" "$dry_run" "$adopt" "$force"; then
      ((success++)) || true
    else
      ((failed++)) || true
    fi
    echo ""
  done
  
  # Summary
  echo -e "${CYAN}Summary:${NC}"
  echo -e "  ${GREEN}Success: $success${NC}"
  [[ $failed -gt 0 ]] && echo -e "  ${RED}Failed: $failed${NC}"
  
  if [[ "$dry_run" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}This was a dry run. Run without -n to apply changes.${NC}"
  fi
}

main "$@"
