# Linux Setup Scripts

A collection of practical Linux setup scripts, desktop configuration files, shell customizations, and small utilities for quickly rebuilding a productive Linux workstation.

The repository is centered around a personal Linux workflow spanning **Arch Linux, Fedora, and CachyOS**, with additional configuration for **Niri**, **DankMaterialShell (DMS)**, **Starship**, Bash/Zsh, development environments, DNS/network management, and browser-based web-app launchers.

> **Important:** These scripts are opinionated and are primarily designed around one user's workstation. Read each script before running it on another machine. Several scripts modify system services, networking, shell startup files, or desktop configuration.

## What is included

| Area | Files | Purpose |
| --- | --- | --- |
| Distribution setup | `arch-setup.sh`, `fedora-setup.sh`, `cachyos-setup.sh` | Install packages and configure a fresh desktop/workstation |
| Web apps | `create-webapp.sh` | Create native-looking `.desktop` launchers for websites |
| DNS / networking | `change-dns.sh` | Inspect DNS, set/reset NetworkManager DNS, and edit `/etc/hosts` |
| Python workspaces | `set_dir.sh` | Create learning directories with Python 3.11 virtual environments |
| Shell | `bashrc`, `zshrc` | Bash/Zsh environment, aliases, prompt integrations, Python/Node tooling |
| Prompt | `starship.toml` | Starship prompt configuration with Git, language, battery, and system context |
| Niri | `niri/` | Niri compositor configuration and DMS integration |
| Windows VM | `windows-vm/docker-compose.yml` | Run a Windows 11 VM through the `dockurr/windows` container |

The repository currently has a `main` branch and is a public, unarchived repository. fileciteturn16file0L2-L10

---

## Quick start

Clone the repository:

```bash
git clone https://github.com/VijetHegde604/linux-setup-scripts.git
cd linux-setup-scripts
```

Make the scripts executable:

```bash
chmod +x *.sh
```

Then choose the script that matches what you want to configure. For example:

```bash
./fedora-setup.sh
```

or:

```bash
./arch-setup.sh
```

Do **not** run all scripts blindly. They target different distributions and system configurations.

---

## Distribution setup scripts

### Arch Linux — `arch-setup.sh`

`arch-setup.sh` is a workstation bootstrap script built around `pacman`, the AUR helper `paru`, systemd, and common desktop/development tooling. The script contains routines for:

- Updating the system with `pacman -Syu`
- Installing base packages such as `base-devel`, Git, curl, wget, Flatpak, Bluetooth packages, `reflector`, `pacman-contrib`, `btop`, fonts, Zed, Fastfetch, `lsd`, `bat`, and `wtype`
- Enabling Bluetooth and package-cache services
- Generating an India-focused Pacman mirror list with `reflector`
- Installing `paru`
- Installing selected AUR packages including Snapper-related tooling and Bruno
- Installing `mise`
- Installing Starship and applying the repository's `starship.toml`
- Installing `create-webapp` into `~/.local/bin`
- Creating an 80% battery charge-threshold systemd service when the kernel exposes the expected battery interface

These operations are implemented as separate functions in the script. fileciteturn2file0L2-L2

### Important: current execution behavior

The Arch script currently leaves several major setup stages **commented out** in `main()`. At present, the active flow runs `install_mise`, Starship configuration, Bash configuration, the custom web-app helper, the battery threshold setup, and cleanup. The package installation, mirror configuration, service enablement, `paru`, and AUR stages are present but not enabled by default. fileciteturn2file0L2-L2

That means the script is better understood as a collection of Arch setup components than as a completely automated fresh-install bootstrap in its current state.

### Arch prerequisites

The script assumes a working Arch installation with:

- `sudo`
- Git
- `curl`
- a functioning package manager
- a writable home directory

Some stages also require AUR/build tooling, systemd, and a compatible laptop battery charge-control interface.

### Battery threshold behavior

The Arch script looks for:

```text
/sys/class/power_supply/BAT0/charge_control_end_threshold
```

If that path exists, it installs and enables a systemd oneshot service that writes `80` to the interface, targeting an 80% charge limit. If the interface does not exist, the script skips this configuration. fileciteturn2file0L2-L2

---

## Fedora — `fedora-setup.sh`

The Fedora script is the most comprehensive end-to-end workstation bootstrap in the repository. It installs a broad package set with `dnf`, configures Flatpak, Chezmoi, Nix, DankLinux, greetd/Niri, a battery threshold service, Zed, Starship, Tailscale, and Plymouth. fileciteturn4file0L2-L2

### Package setup

The script installs packages including:

- Flatpak
- `lsd`, `bat`, `wtype`
- GNOME keyring and Seahorse
- Chezmoi
- zoxide, ripgrep, fd-find, duf, fzf, wget
- VLC, Nautilus
- greetd
- `cava`
- GTK/KDE image format packages
- Adwaita GTK theme and Plymouth spinner theme
- XDG user directories
- Intel Wi-Fi firmware
- Fastfetch
- Nix
- Noto color emoji fonts
- SOF audio firmware
- Power Profiles Daemon
- Git credential helper support
- btop

The script uses `sudo dnf install -y` and is intended to be repeatable for already-installed packages. fileciteturn4file0L2-L2

### Other components

The script also provides functions for:

- Installing Vicinae
- Installing LazyGit through the `atim/lazygit` COPR
- Configuring Flathub
- Installing Jellyfin Desktop and Gear Lever
- Initializing/applying `VijetHegde604/dots.git` through Chezmoi
- Installing Nix in daemon mode when necessary
- Installing DankLinux
- Creating and enabling an 80% battery-threshold service
- Configuring greetd to launch `niri-session`
- Installing Zed
- Installing and enabling Tailscale
- Installing Starship
- Selecting the Plymouth spinner theme

fileciteturn4file0L2-L2

### Chezmoi integration

On first setup, the Fedora script asks for a Git username and email and writes them to:

```text
~/.config/chezmoi/chezmoi.toml
```

It then initializes and applies the dotfiles repository:

```text
https://github.com/VijetHegde604/dots.git
```

If the Chezmoi source directory already exists, it runs `chezmoi apply` instead. fileciteturn4file0L2-L2

### greetd + Niri

The Fedora setup configures `greetd` with an `initial_session` that launches:

```text
niri-session
```

It backs up the existing greetd configuration before appending the new session configuration and then enables greetd. This is a login-manager change and should be reviewed carefully before running on a machine where GDM/SDDM or another display manager is already configured. fileciteturn4file0L2-L2

---

## CachyOS — `cachyos-setup.sh`

Despite its filename, the current CachyOS script is focused on a specific utility: **creating browser-based web applications as desktop launchers**.

It:

1. Requires `curl`.
2. Prefers Brave and falls back to `brave`, `google-chrome`, or `chromium` if available.
3. Prompts for an application name and URL.
4. Converts the application name into a sanitized slug.
5. Creates `~/.local/share/icons` and `~/.local/share/applications`.
6. Attempts to download an icon from the Dashboard Icons project.
7. Falls back to a favicon service if the Dashboard Icons lookup fails.
8. Generates a `.desktop` entry using Chromium's `--app` mode.
9. Refreshes the application database when `update-desktop-database` is installed.

fileciteturn3file0L2-L2

Because the script is effectively a web-app/PWA helper rather than a complete CachyOS bootstrap, this name may be worth revisiting in a future cleanup.

---

## Web-app launcher — `create-webapp.sh`

`create-webapp.sh` is a standalone version of the web-app creator and is the easiest script in the repository to reuse independently.

### What it does

The script detects the system's default HTTP browser from the XDG MIME configuration, resolves its `.desktop` file, extracts the browser executable, and then asks for:

- Application name
- URL
- Optional icon URL

It creates:

```text
~/.local/share/icons/<slug>.png
~/.local/share/applications/<slug>.desktop
```

and writes a launcher using:

```text
--app=<URL>
```

The generated desktop entry also sets a custom `StartupWMClass`, making web applications behave more like separate desktop applications. fileciteturn6file0L2-L2

### Usage

```bash
chmod +x create-webapp.sh
./create-webapp.sh
```

Example input:

```text
Enter App Name: Jellyfin
Enter URL: http://192.168.1.100:8096
Enter Icon URL: <press Enter>
```

### Icon handling

When no icon URL is supplied, the script attempts to retrieve an icon from:

```text
walkxcode/dashboard-icons
```

If no matching icon is available, it falls back to the generic `web-browser` icon. fileciteturn6file0L2-L2

---

## DNS and `/etc/hosts` tool — `change-dns.sh`

`change-dns.sh` is an interactive NetworkManager-oriented DNS utility.

### Menu

The current menu provides:

```text
1) Show DNS provider + resolv.conf
2) Show active DNS servers
3) Set custom DNS (auto active connection)
4) Reset DNS to automatic (auto active connection)
5) Add custom domain->IP entry (/etc/hosts)
0) Exit
```

fileciteturn5file0L2-L2

### DNS inspection

The tool checks whether `systemd-resolved` and NetworkManager are active, reports whether `/etc/resolv.conf` is a symlink, prints its current contents, and uses `resolvectl status` when available. fileciteturn5file0L2-L2

### Setting DNS

The script determines the connection associated with the default route and uses `nmcli` to:

- disable automatic IPv4 DNS
- set custom DNS servers
- optionally set a DNS search domain
- reconnect the active connection

fileciteturn5file0L2-L2

### Resetting DNS

The reset action restores DHCP-provided DNS by clearing the custom DNS settings and disabling `ipv4.ignore-auto-dns`. fileciteturn5file0L2-L2

### `/etc/hosts`

The tool can add a custom `IP domain` mapping to `/etc/hosts`, while checking for a matching existing entry before appending it. fileciteturn5file0L2-L2

### Requirements

The DNS-changing functions expect:

- NetworkManager
- `nmcli`
- `ip`
- `systemctl`
- `sudo`

Running the tool on a system managed by a different network stack may require adaptation.

---

## Python workspace generator — `set_dir.sh`

`set_dir.sh` is a small interactive helper for creating Python learning/project directories under:

```text
~/learning
```

For each directory name you enter, it:

1. Creates `~/learning/<name>`.
2. Enters the directory.
3. Selects Python 3.11 through pyenv.
4. Creates a virtual environment named after the directory.
5. Returns to the previous directory.

fileciteturn7file0L2-L2

### Requirements

The script requires `pyenv`. If Python 3.11 is missing, it attempts to install it with:

```bash
pyenv install 3.11
```

fileciteturn7file0L2-L2

### Usage

```bash
chmod +x set_dir.sh
./set_dir.sh
```

Then enter one project/directory name per line and press `Ctrl+D` when finished.

---

## Shell configuration

### `bashrc`

The repository's Bash configuration:

- Adds `~/.local/bin` and `~/bin` to `PATH`
- Sources `~/.bashrc.d/*`
- Changes `cd` to the `zoxide` command
- Uses `lsd` for `ls`
- Defines a tree-style `lt` alias
- Adds Docker start/stop aliases
- Initializes Starship
- Initializes `mise`
- Initializes zoxide
- Sets `TERM=xterm-256color`

fileciteturn8file0L2-L2

> **Portability note:** the checked-in Bash configuration contains a hard-coded `mise` path under `/home/vijeth`. Replace that path with `$HOME/.local/bin/mise` before copying the file to another account. fileciteturn8file0L2-L2

### `zshrc`

The Zsh configuration:

- Adds local user binaries to `PATH`
- Initializes NVM
- Initializes pyenv
- Initializes zoxide
- Defines a Git-aware prompt
- Sets the terminal type

fileciteturn9file0L2-L2

---

## Starship prompt — `starship.toml`

The Starship configuration provides a two-line development-oriented prompt with:

- user and hostname
- working directory
- Python virtual environment
- Node.js, Rust, and Go context
- package information
- Git branch and status
- command duration
- error status
- time
- battery status

It uses a custom `material_vijet` palette and Nerd Font symbols for a compact terminal UI. fileciteturn10file0L2-L2

Copy it to the normal Starship location with:

```bash
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml
```

---

## Niri configuration

The `niri/` directory contains a modular Niri setup.

The top-level `niri/config.kdl` configures:

- keyboard/touchpad behavior
- focus-follows-mouse
- transparent layout background
- preset column widths
- window shadows
- Quickshell layer-shell placement
- overview behavior
- animation tuning
- application-specific window rules
- floating rules for utilities and selected applications
- recent-window switching
- separate external files for colors, layout, Alt-Tab, keybindings, outputs, and cursor configuration

fileciteturn12file0L2-L2

The `niri/dms/` directory contains the modular DMS-related KDL files:

```text
niri/dms/
├── alttab.kdl
├── binds.kdl
├── colors.kdl
├── cursor.kdl
├── layout.kdl
├── outputs.kdl
└── wpblur.kdl
```

The repository's Niri configuration explicitly includes the DMS files used by the compositor configuration. fileciteturn13file0L2-L2 fileciteturn12file0L2-L2

### Installing the Niri configuration

The repository does not currently provide a single installer for the Niri configuration. Copy or link the configuration into the location expected by your Niri installation, then make sure the referenced `dms/*.kdl` files are also present.

Before activating it, verify that:

- Niri is installed
- the included paths match your Niri config location
- any DMS/Quickshell dependencies are installed
- output names and keyboard shortcuts match your hardware

---

## Windows 11 container VM

`windows-vm/docker-compose.yml` defines a Windows 11 virtual machine using the `dockurr/windows` image.

The container is configured with:

- `/dev/kvm`
- `/dev/net/tun`
- `NET_ADMIN`
- web management on port `8006`
- RDP on TCP/UDP `3389`
- persistent storage in `./windows:/storage`
- automatic restart
- a two-minute stop grace period

fileciteturn15file0L2-L2

### Start the VM

From the repository root:

```bash
cd windows-vm
docker compose up -d
```

Then access the management UI at:

```text
http://localhost:8006
```

RDP can be reached through port `3389` when the VM is configured and running.

### Requirements

The host should have:

- Docker Engine
- Docker Compose
- hardware virtualization enabled
- a working `/dev/kvm`

This configuration also grants the container `NET_ADMIN`, so review the networking implications before exposing it beyond the local host.

---

## Recommended workflow

For a fresh Linux machine, a safer workflow is:

1. Install the distribution normally.
2. Clone this repository.
3. Read the relevant setup script and comment out anything machine-specific.
4. Run the setup script.
5. Log out/reboot when the script changes the display manager, login session, kernel interfaces, or system services.
6. Apply individual configuration files such as Starship, Bash/Zsh, and Niri only after verifying their paths and dependencies.

Avoid treating the repository as a universal one-command installer. It is better viewed as a **personal Linux workstation toolbox** whose pieces can be applied selectively.

---

## Safety and portability notes

### Review before running

Several scripts execute commands with `sudo` or alter system state. In particular:

- package installation and system updates
- systemd services
- battery charge thresholds
- greetd and login-session configuration
- DNS/network settings
- `/etc/hosts`

Read the relevant function before running it on an unfamiliar machine.

### External install scripts

The setup scripts use several remote installer patterns such as:

```bash
curl ... | sh
```

This appears in the repository for tools including `mise`, Starship, Vicinae, Nix, DankLinux, Zed, and Tailscale. fileciteturn2file0L2-L2 fileciteturn4file0L2-L2

For higher-assurance environments, download and inspect those installers first instead of piping remote content directly into a shell.

### Machine-specific assumptions

The repository contains several assumptions that should be adjusted before sharing these scripts broadly:

- India-specific Arch mirror selection
- hard-coded `/home/vijeth` path in `bashrc`
- `BAT0` battery naming
- a specific Niri/DMS layout
- particular browser/desktop behavior
- specific package names for Fedora/Arch

---

## Known limitations and cleanup opportunities

The current repository works well as a personal toolbox, but a few areas could be improved for wider reuse:

### 1. Separate bootstrap from utilities

`cachyos-setup.sh` currently behaves as a web-app creator rather than a full CachyOS setup script. Consider renaming it to make its purpose obvious.

### 2. Use `$HOME` instead of hard-coded paths

The Bash configuration should use `$(dirname ...)` or `$HOME` rather than `/home/vijeth`.

### 3. Add explicit dependencies

A small `README` dependency table or per-script prerequisite section makes the tools much easier to reuse.

### 4. Add shell linting

Consider running:

```bash
shellcheck *.sh
```

and optionally formatting Bash scripts with `shfmt`.

### 5. Make bootstrap modes explicit

For the Arch script, consider command-line flags such as:

```text
--packages
--aur
--shell
--battery
--webapps
```

This would make the current commented-out execution path safer and easier to maintain.

### 6. Add backups before replacing user config

For files such as `~/.bashrc`, consider creating a timestamped backup before replacing an existing file.

---

## File tree

```text
linux-setup-scripts/
├── arch-setup.sh
├── bashrc
├── cachyos-setup.sh
├── change-dns.sh
├── create-webapp.sh
├── fedora-setup.sh
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
├── set_dir.sh
├── starship.toml
├── windows-vm/
│   └── docker-compose.yml
└── zshrc
```

The repository root currently contains these setup scripts, shell/config files, and the two configuration directories shown above. fileciteturn1file0L2-L2

---

## Contributing

This repository is primarily a personal collection of workstation automation. When adding a script:

- keep it focused on one task
- use `set -euo pipefail` for Bash scripts where appropriate
- check prerequisites early
- avoid hard-coded usernames and machine-specific paths
- make destructive/system-wide changes obvious
- prefer idempotent operations where possible
- document external dependencies and side effects

For larger changes, include a short usage example in this README.

---

## License

No license file is currently included in the repository. Until a license is added, treat the contents as **all rights reserved** and do not assume permission to redistribute or modify them beyond what GitHub's repository interface permits.
