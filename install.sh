#!/usr/bin/env bash
# ==============================================================================
# macOS Homebrew Bootstrap & Installation Script
# ==============================================================================
# This script sets up Homebrew on a clean macOS installation (Apple Silicon or
# Intel) and installs all formulas, casks, and packages defined in the Brewfile.
# ==============================================================================

set -euo pipefail

# Text styling
BOLD="\033[1m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

info() {
    printf "${BLUE}${BOLD}[INFO]${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}${BOLD}[SUCCESS]${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}${BOLD}[WARNING]${NC} %s\n" "$1"
}

error() {
    printf "${RED}${BOLD}[ERROR]${NC} %s\n" "$1" >&2
}

abort() {
    error "$1"
    exit 1
}

# 1. Verify macOS
if [[ "$(uname -s)" != "Darwin" ]]; then
    abort "This script is designed for macOS (OS X) only. Detected: $(uname -s)"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BREWFILE="${SCRIPT_DIR}/Brewfile"

if [[ ! -f "${BREWFILE}" ]]; then
    abort "Brewfile not found at ${BREWFILE}. Please make sure you are running this script inside the dotfiles repository."
fi

info "Starting macOS environment setup..."
info "Repository path: ${SCRIPT_DIR}"

# 2. Check Xcode Command Line Tools
info "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    warn "Xcode Command Line Tools not detected."
    info "Initiating Xcode Command Line Tools installation..."
    xcode-select --install || true

    echo ""
    warn "A macOS dialog should have appeared asking to install Command Line Tools."
    echo -n "Please complete that installation, then press [ENTER] here to continue..."
    read -r _

    # Verify installation completed
    if ! xcode-select -p &>/dev/null; then
        abort "Xcode Command Line Tools were not detected after waiting. Please re-run after installation completes."
    fi
fi
success "Xcode Command Line Tools are installed."

# 3. Locate or Install Homebrew
info "Checking for Homebrew installation..."
HAS_BREW=false

if command -v brew &>/dev/null; then
    HAS_BREW=true
elif [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]; then
    HAS_BREW=true
fi

if [[ "${HAS_BREW}" == false ]]; then
    info "Homebrew not found. Installing Homebrew from official repository..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# 4. Configure Shell Environment (Apple Silicon vs Intel)
ARCH="$(uname -m)"
if [[ "${ARCH}" == "arm64" ]] && [[ -x "/opt/homebrew/bin/brew" ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
elif [[ -x "/usr/local/bin/brew" ]]; then
    BREW_BIN="/usr/local/bin/brew"
elif command -v brew &>/dev/null; then
    BREW_BIN="$(command -v brew)"
else
    abort "Homebrew installation completed, but brew executable was not found."
fi

# Export brew shell environment into current script execution
eval "$("${BREW_BIN}" shellenv)"
success "Homebrew active: $("${BREW_BIN}" --version | head -n 1)"

# Ensure Homebrew is configured in user's zprofile (macOS default shell is zsh)
ZPROFILE="${HOME}/.zprofile"
SHELLENV_CMD="eval \"\$(${BREW_BIN} shellenv)\""

if [[ -f "${ZPROFILE}" ]]; then
    if ! grep -Fq "brew shellenv" "${ZPROFILE}"; then
        info "Adding Homebrew shellenv to ${ZPROFILE}..."
        echo "" >> "${ZPROFILE}"
        echo "# Load Homebrew environment" >> "${ZPROFILE}"
        echo "${SHELLENV_CMD}" >> "${ZPROFILE}"
        success "Updated ${ZPROFILE}"
    fi
else
    info "Creating ${ZPROFILE} with Homebrew shellenv..."
    echo "# Load Homebrew environment" > "${ZPROFILE}"
    echo "${SHELLENV_CMD}" >> "${ZPROFILE}"
    success "Created ${ZPROFILE}"
fi

# 5. Update Homebrew and Install Bundle
info "Updating Homebrew formula database..."
brew update

info "Installing packages from ${BREWFILE}..."
info "This may take a few minutes depending on your internet connection and packages..."

# Run brew bundle without creating a lockfile
brew bundle --file="${BREWFILE}" --no-lock

success "All Brewfile packages have been successfully processed!"

# 6. Verify System Health
info "Running brew doctor..."
if brew doctor; then
    success "Homebrew health check passed!"
else
    warn "brew doctor reported some warnings. You can review them above."
fi

echo ""
printf "${GREEN}${BOLD}==============================================================================${NC}\n"
printf "${GREEN}${BOLD} Installation Complete!${NC}\n"
printf "${GREEN}${BOLD}==============================================================================${NC}\n"
printf "Next steps:\n"
printf "  1. Restart your terminal or run: ${BOLD}source ~/.zprofile${NC}\n"
printf "  2. For GUI applications (casks), launch them from Applications or Spotlight.\n"
printf "  3. Grant any required macOS permissions (Accessibility/Screen Recording in System Settings).\n\n"
