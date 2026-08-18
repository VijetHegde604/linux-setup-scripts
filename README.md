# Linux Setup Scripts

A collection of personal Linux workstation setup scripts, shell configuration, desktop configuration, and small utilities.

The repository currently targets **Arch Linux and Fedora**, with standalone tools for DNS/networking, Python environments, web-app launchers, shell customization, **Niri + DankMaterialShell**, and a Windows 11 VM through Docker.

> **Warning:** These are opinionated workstation scripts. Read the relevant script before running it. Some operations modify system packages, services, networking, login managers, battery charging behavior, or user configuration.

## Quick Start

```bash
git clone https://github.com/VijetHegde604/linux-setup-scripts.git
cd linux-setup-scripts
chmod +x *.sh
```

Run only the component you need:

```bash
./arch-setup.sh
./fedora-setup.sh
./change-dns.sh
./create-webapp.sh
./set_dir.sh
```

There is no universal `install.sh`; the repository is intended to be used selectively.

## Repository Structure

```text
linux-setup-scripts/
├── arch-setup.sh
├── fedora-setup.sh
├── change-dns.sh
├── create-webapp.sh
├── set_dir.sh
├── bashrc
├── zshrc
├── starship.toml
├── niri/
│   ├── config.kdl
│   └── dms/
│       ├── alttab.kdl
│       ├── binds.kdl
│       ├── colors.kdl
│       ├── cursor.kdl
│       ├── layout.kdl
│       ├── outputs.kdl
│       └── wpblur.kdl
├── windows-vm/
│   └── docker-compose.yml
├── .gitignore
└── README.md
```

## Setup Scripts

### Arch Linux — `arch-setup.sh`

The Arch script contains functions for:

- System updates with `pacman`
- Base workstation packages
- Bluetooth and package-cache services
- India-focused Pacman mirrors via `reflector`
- `paru` installation
- Selected AUR packages
- `mise`
- Starship
- Bash configuration
- The custom web-app launcher
- An 80% battery charge threshold when supported

The current `main()` intentionally has the package/mirror/service/AUR stages commented out. The active flow configures `mise`, Starship, Bash, the web-app helper, battery charging, and cleanup.

```bash
./arch-setup.sh
```

The script assumes an Arch system with `sudo`, systemd, and the normal package-management tooling.

### Fedora — `fedora-setup.sh`

The Fedora bootstrap installs and configures a broader workstation stack, including:

- DNF packages
- Flatpak / Flathub
- Chezmoi
- Nix
- DankLinux
- greetd + Niri
- Starship
- Zed
- Tailscale
- Vicinae
- LazyGit
- Jellyfin Desktop
- Gear Lever
- Power Profiles Daemon
- Plymouth
- Common CLI/development tools
- Battery charge limiting

It also integrates the author's Chezmoi dotfiles repository.

```bash
./fedora-setup.sh
```

**Important:** the script changes the login manager by configuring `greetd` to start `niri-session`. Review this before running it on an existing desktop installation.

## Standalone Utilities

### Web App Creator — `create-webapp.sh`

Creates a `.desktop` launcher for a website and opens it in browser application mode.

The script:

1. Detects the default HTTP browser through XDG settings.
2. Resolves the browser executable.
3. Prompts for an application name and URL.
4. Optionally downloads an icon.
5. Creates a launcher under `~/.local/share/applications/`.
6. Stores icons under `~/.local/share/icons/`.

```bash
./create-webapp.sh
```

The generated browser command uses:

```text
--app=<URL>
```

This is useful for turning self-hosted services, dashboards, webmail, and other frequently used sites into desktop applications.

### DNS Manager — `change-dns.sh`

An interactive NetworkManager DNS utility.

It can:

- Inspect `/etc/resolv.conf`
- Show active DNS servers
- Inspect `systemd-resolved`
- Set custom DNS servers on the active NetworkManager connection
- Reset DNS to DHCP/automatic
- Add custom hostname-to-IP entries to `/etc/hosts`

```bash
./change-dns.sh
```

Requirements:

- NetworkManager
- `nmcli`
- `ip`
- `systemctl`
- `sudo`

### Python Workspace Generator — `set_dir.sh`

Creates Python learning/project directories under:

```text
~/learning
```

For each name entered, it:

1. Creates the directory.
2. Uses pyenv to select Python 3.11.
3. Creates a virtual environment with the same name.
4. Writes the local pyenv version.

```bash
./set_dir.sh
```

Enter one directory name per line and press `Ctrl+D` when finished.

Requirements:

- Bash
- pyenv
- Python 3.11 through pyenv

If Python 3.11 is missing, the script attempts:

```bash
pyenv install 3.11
```

## Shell Configuration

### Bash — `bashrc`

The Bash configuration provides:

- `~/.local/bin` and `~/bin` in `PATH`
- `zoxide` as `cd`
- `lsd` as `ls`
- `lt` as an `lsd --tree` shortcut
- Docker start/stop aliases
- Starship initialization
- mise initialization
- zoxide initialization

Notable aliases:

```bash
alias cd="z"
alias ls='lsd'
alias lt='lsd --tree'
alias start-docker='sudo systemctl start docker'
alias stop-docker='sudo systemctl stop docker && sudo systemctl stop docker.socket'
```

**Portability note:** the current Bash configuration contains a hard-coded `/home/vijeth/.local/bin/mise` path. Replace it with a portable `$HOME`-based path when using it on another account.

### Zsh — `zshrc`

The Zsh configuration provides:

- User-local `PATH`
- NVM initialization
- pyenv initialization
- zoxide initialization
- A Git-aware prompt
- Terminal environment configuration

## Starship — `starship.toml`

A custom development-oriented Starship prompt using the `material_vijet` palette.

The configuration can show:

- Username and hostname
- Current directory
- Python environment
- Node.js
- Rust
- Go
- Package information
- Git branch/status
- Command duration
- Exit status
- Time
- Battery status

Install it with:

```bash
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml
```

## Niri Configuration

`niri/` contains a modular configuration for the Niri Wayland compositor.

### `niri/config.kdl`

The main configuration covers:

- Keyboard and touchpad behavior
- Focus-follows-mouse
- Transparent layout background
- Column width presets
- Window shadows
- Quickshell layer-shell handling
- Overview behavior
- Animations
- Application-specific window rules
- Floating windows
- Recent-window switching
- Screenshot paths

It includes:

```text
dms/colors.kdl
dms/layout.kdl
dms/alttab.kdl
dms/binds.kdl
dms/outputs.kdl
dms/cursor.kdl
```

### DMS integration

The DMS files provide:

- Keybindings
- Colors
- Layout settings
- Alt-Tab appearance
- Display/output configuration
- Cursor configuration
- Wallpaper blur layer rules

The keybindings integrate directly with DMS for features such as:

- Spotlight/application launcher
- Clipboard
- Process list
- Power menu
- Settings
- Wallpaper browser
- Notifications
- Notepad
- Lock screen
- Audio controls
- Brightness controls

The current display configuration targets:

```text
eDP-1
1920x1200 @ 60 Hz
scale 1.25
```

This is hardware-specific and should be changed for other displays.

> **DMS-generated files:** `colors.kdl`, `layout.kdl`, `alttab.kdl`, `outputs.kdl`, and `wpblur.kdl` contain generated configuration. Some explicitly warn that manual changes may be overwritten by DMS.

## Windows 11 VM

`windows-vm/docker-compose.yml` runs a Windows 11 VM using `dockurr/windows`.

It provides:

| Port | Purpose |
|---:|---|
| `8006` | Web management UI |
| `3389/tcp` | RDP |
| `3389/udp` | RDP UDP |

The container receives:

```text
/dev/kvm
/dev/net/tun
NET_ADMIN
```

VM storage is persisted at:

```text
./windows:/storage
```

Start it:

```bash
cd windows-vm
docker compose up -d
```

Open:

```text
http://localhost:8006
```

Stop it:

```bash
docker compose down
```

Requirements:

- Docker Engine
- Docker Compose
- CPU virtualization
- `/dev/kvm`
- Sufficient RAM and disk space

## Dependencies

| Component | Main requirements |
|---|---|
| `arch-setup.sh` | Arch Linux, `sudo`, pacman, systemd |
| `fedora-setup.sh` | Fedora, `sudo`, dnf, systemd |
| `change-dns.sh` | NetworkManager, `nmcli`, `ip`, `sudo` |
| `create-webapp.sh` | Bash, XDG tools, `curl`, compatible browser |
| `set_dir.sh` | Bash, pyenv, Python 3.11 |
| `bashrc` | Bash, Starship, zoxide, lsd, mise |
| `zshrc` | Zsh, NVM, pyenv, zoxide |
| `starship.toml` | Starship |
| `niri/` | Niri, DMS/Quickshell components |
| `windows-vm/` | Docker, Compose, KVM |

## Safety and Portability

Read scripts before execution. Several components use `sudo` or change system state.

Pay particular attention to:

- Package installation and system updates
- systemd services
- Battery charging limits
- `greetd`
- Niri session configuration
- DNS settings
- `/etc/hosts`
- Tailscale
- Boot splash configuration

### Machine-specific assumptions

The repository contains personal-machine assumptions such as:

- `/home/vijeth`
- `BAT0`
- `eDP-1`
- `1920x1200`
- 125% display scaling
- Specific applications such as Ghostty and DMS
- India-specific Arch mirror configuration

These should be reviewed before reuse.

### Remote installers

Some setup functions download third-party installation scripts with patterns such as:

```bash
curl ... | sh
```

For security-sensitive environments, inspect remote installers before executing them.

## Development

Run Bash syntax checks:

```bash
bash -n arch-setup.sh
bash -n fedora-setup.sh
bash -n change-dns.sh
bash -n create-webapp.sh
bash -n set_dir.sh
```

Run ShellCheck:

```bash
shellcheck *.sh
```

If using `shfmt`:

```bash
shfmt -d *.sh
```

When adding scripts:

- Keep them focused.
- Check dependencies early.
- Prefer idempotent operations.
- Avoid hard-coded usernames.
- Make system-wide changes obvious.
- Document prerequisites and side effects.

## `.gitignore`

The repository currently ignores:

```text
*.log
*.tar.gz
```

This keeps setup logs and tar archives out of version control.

## License

No license file is currently present. Until a license is added, assume the repository contents are **all rights reserved**.
