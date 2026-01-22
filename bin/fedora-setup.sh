#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Do not run this script as root. It will use sudo when needed."
    fi
}

# RPM Fusion Setup
setup_rpmfusion() {
    info "Setting up RPM Fusion repositories..."
    
    if ! rpm -q rpmfusion-free-release &>/dev/null; then
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        success "RPM Fusion repositories installed"
    else
        success "RPM Fusion repositories already installed"
    fi
}

# COPR Repositories
setup_coprs() {
    info "Setting up COPR repositories..."
    
    local coprs=(
        "atim/starship"
        "scottames/ghostty"
        "peterwu/rendezvous"
        "jdxcode/mise"
        "dejan/lazygit"
        "lihaohong/yazi"
        "agriffis/neovim-nightly"
    )
    
    for copr in "${coprs[@]}"; do
        if ! sudo dnf copr list --enabled 2>/dev/null | grep -q "$copr"; then
            sudo dnf copr enable -y "$copr"
            success "Enabled COPR: $copr"
        else
            success "COPR already enabled: $copr"
        fi
    done
}

# External Repositories
setup_external_repos() {
    info "Setting up external repositories..."
    
    # Tailscale
    if [[ ! -f /etc/yum.repos.d/tailscale.repo ]]; then
        sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
        success "Tailscale repository added"
    else
        success "Tailscale repository already configured"
    fi
}

# DNF Group Install
install_groups() {
    info "Installing package groups..."
    sudo dnf group install -y development-tools
    success "Development Tools group installed"
}

# DNF Packages
install_packages() {
    info "Installing DNF packages..."
    
    local packages=(
        # Editors & File Managers
        micro
        neovim
        python3-neovim
        yazi
        dolphin
        
        # Shell & Prompt
        starship
        
        # Terminals
        ghostty
        kitty
        
        # System
        distrobox
        tuned-ppd
        tailscale
        et
        mosh
        
        # Media
        mpd
        mpv
        playerctl
        mpc
        yt-dlp
        
        # CLI Utilities
        ripgrep
        fd-find
        zoxide
        fzf
        tldr
        btop
        fastfetch
        jq
        git-delta
        lazygit
        bat
        direnv
        shellcheck
        trash-cli
        mise
        wl-clipboard
        
        # Mail
        aerc
        
        # Documents
        zathura
        zathura-pdf-mupdf
        file-roller
        
        # Theming
        papirus-icon-theme
        bibata-cursor-themes
        
        # Sync
        syncthing
        
        # Browser
        qutebrowser
        
        # Gaming
        steam
        
        # Build dependencies for cargo/go packages
        golang
        cargo
        rust
        gcc
        pkg-config
        openssl-devel
        alsa-lib-devel
        sqlite-devel
    )
    
    sudo dnf install -y "${packages[@]}"
    success "DNF packages installed"
}

# Codecs
install_codecs() {
    info "Installing multimedia codecs..."
    
    sudo dnf install -y \
        libavcodec-freeworld \
        mesa-va-drivers-freeworld \
        mesa-vdpau-drivers-freeworld
    
    success "Multimedia codecs installed"
}

# AMD ROCm
install_rocm() {
    info "Installing AMD ROCm support..."
    
    sudo dnf install -y \
        rocm-hip \
        rocm-opencl \
        rocm-rpm-macros \
        rocm-runtime \
        rocm-smi \
        rocminfo
    
    success "AMD ROCm installed"
}

# Flatpak
setup_flatpaks() {
    info "Setting up Flatpak and installing apps..."
    
    # Ensure Flathub is added
    if ! flatpak remote-list | grep -q flathub; then
        sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        success "Flathub repository added"
    fi
    
    local flatpaks=(
        com.discordapp.Discord
        org.signal.Signal
        app.zen_browser.zen
        org.nicotine_plus.Nicotine
        com.github.tchx84.Flatseal
        dev.deedles.Trayscale
        org.gnome.World.PikaBackup
        io.missioncenter.MissionCenter
        io.github.giantpinkrobots.flatsweep
        io.github.dvlv.boxbuddyrs
        com.obsproject.Studio
        com.bitwarden.desktop
        com.usebottles.bottles
    )
    
    for app in "${flatpaks[@]}"; do
        if ! flatpak list --app | grep -q "$app"; then
            sudo flatpak install -y flathub "$app"
            success "Installed Flatpak: $app"
        else
            success "Flatpak already installed: $app"
        fi
    done
}

# Nerd Fonts
install_nerdfonts() {
    info "Installing Nerd Fonts (Symbols Only)..."
    
    local font_dir="$HOME/.local/share/fonts"
    local font_name="NerdFontsSymbolsOnly"
    
    if [[ -d "$font_dir/$font_name" ]]; then
        success "Nerd Fonts Symbols already installed"
        return
    fi
    
    mkdir -p "$font_dir"
    
    # Get latest release version
    local version
    version=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | jq -r '.tag_name')
    
    info "Downloading Nerd Fonts $version..."
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    curl -fLo "$tmp_dir/$font_name.tar.xz" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/${version}/${font_name}.tar.xz"
    
    mkdir -p "$font_dir/$font_name"
    tar -xf "$tmp_dir/$font_name.tar.xz" -C "$font_dir/$font_name"
    
    rm -rf "$tmp_dir"
    
    # Refresh font cache
    fc-cache -fv &>/dev/null
    
    success "Nerd Fonts Symbols installed"
}

# Cursor Theme
setup_cursor_theme() {
    info "Setting Bibata-Original-Classic as default cursor..."
    
    sudo mkdir -p /usr/share/icons/default
    sudo tee /usr/share/icons/default/index.theme > /dev/null <<EOF
[Icon Theme]
Inherits=Bibata-Original-Classic
EOF
    
    success "Default cursor theme set"
}

# Cargo/Go Packages
install_cargo_go_packages() {
    info "Installing packages via cargo and go..."
    
    # Cargo packages
    info "Installing Rust packages (this may take a while)..."
    cargo install rmpc
    cargo install listenbrainz-mpd
    cargo install mpd-discord-rpc
    success "Cargo packages installed"
    
    # Go packages
    info "Installing Go packages..."
    go install github.com/natsukagami/mpd-mpris/cmd/mpd-mpris@latest
    success "Go packages installed"
    
    # Ensure cargo and go bin directories are in PATH
    warn "Make sure ~/.cargo/bin and ~/go/bin are in your PATH"
}

# Mise Setup
setup_mise() {
    info "Setting up mise-managed tools..."
    
    # Initialize mise if needed
    if command -v mise &>/dev/null; then
        mise use -g eza@latest
        success "eza installed via mise"
    else
        warn "mise not found in PATH. Run 'mise use -g eza' after adding mise to your shell."
    fi
}

# Enable Services
enable_services() {
    info "Enabling and starting services..."
    
    # Tailscale
    sudo systemctl enable --now tailscaled
    success "tailscaled enabled and started"
    
    # Syncthing (user service)
    systemctl --user enable --now syncthing
    success "syncthing user service enabled and started"
    
    # Tuned
    sudo systemctl enable --now tuned
    success "tuned enabled and started"
    
    warn "Run 'sudo tailscale up' to connect to your Tailscale network"
}

# Main
main() {
    echo ""
    echo "  Fedora KDE Workstation Setup Script  "
    echo ""
    
    check_root
    
    setup_rpmfusion
    setup_coprs
    setup_external_repos
    install_groups
    install_packages
    install_codecs
    install_rocm
    setup_flatpaks
    install_nerdfonts
    setup_cursor_theme
    install_cargo_go_packages
    setup_mise
    enable_services
    
    echo ""
    success "Setup complete!"
    echo ""
    info "Next steps:"
    echo "  1. Log out and back in (or reboot) for all changes to take effect"
    echo "  2. Run 'sudo tailscale up' to connect to Tailscale"
    echo "  3. Ensure ~/.cargo/bin and ~/go/bin are in your PATH"
    echo "  4. Run your dotfiles installer to apply configurations"
    echo ""
}

main "$@"
