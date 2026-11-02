# macOS Dotfiles & Homebrew Setup

A lightweight, automated dotfiles repository to back up and bootstrap installed software, command-line utilities, and desktop applications across MacBooks using [Homebrew](https://brew.sh/).

Works seamlessly on both **Apple Silicon** (`arm64` - M1/M2/M3/M4) and **Intel** (`x86_64`) MacBooks running macOS / OS X.

---

## Repository Contents

| File | Description |
| :--- | :--- |
| [`Brewfile`](file:///Users/alexiswilliams/Documents/GitHub/dotfiles/Brewfile) | Declarative manifest of all taps, CLI tools, casks (GUI apps), Go tools, and npm global packages. |
| [`install.sh`](file:///Users/alexiswilliams/Documents/GitHub/dotfiles/install.sh) | Automated bash script to install Xcode Command Line Tools, install Homebrew, configure `PATH`, and run `brew bundle`. |
| [`.gitignore`](file:///Users/alexiswilliams/Documents/GitHub/dotfiles/.gitignore) | Ignores macOS metadata (`.DS_Store`) and temporary bundle lockfiles. |

---

## Quickstart: Setting Up a New MacBook

Follow these steps on your new or freshly restored MacBook:

### 1. Open Terminal
Open **Terminal.app** (via Spotlight: press `Cmd + Space` and search for "Terminal").

### 2. Clone This Repository
Clone your private repository into your preferred directory (e.g., `~/dotfiles` or `~/Documents/GitHub/dotfiles`):

```bash
# Using SSH (if your SSH keys are already configured):
git clone git@github.com:<your-username>/dotfiles.git ~/dotfiles

# OR using HTTPS:
git clone https://github.com/<your-username>/dotfiles.git ~/dotfiles
```

> [!TIP]
> If `git` is not yet available on a brand-new Mac, running `git` will prompt macOS to install the Xcode Command Line Tools automatically. Once finished, run the clone command again.

### 3. Run the Installation Script
Navigate into the repository directory and run the setup script:

```bash
cd ~/dotfiles
./install.sh
```

*(If needed, ensure executable permissions with `chmod +x install.sh`)*

---

## What `install.sh` Does

The script executes the following automated pipeline:

1. **OS Check**: Verifies that the operating system is macOS (`Darwin`).
2. **Xcode Command Line Tools**: Checks for Command Line Tools via `xcode-select -p`. If absent, triggers the macOS installer dialog and waits for you to finish.
3. **Homebrew Bootstrap**:
   - Detects if Homebrew is already installed.
   - If missing, downloads and runs the official Homebrew installer (`https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh`).
4. **Architecture & Shell Environment**:
   - Automatically detects Apple Silicon (`/opt/homebrew`) vs. Intel (`/usr/local`).
   - Evaluates `brew shellenv` for the current execution context.
   - Adds the `brew shellenv` initialization to your `~/.zprofile` (zsh is the default macOS shell) so `brew` is permanently available in future terminal sessions.
5. **Bundle Installation**: Runs `brew bundle --file=Brewfile` to install all declared:
   - **Taps**: Custom repositories (e.g., Cloudflare)
   - **Formulae**: CLI binaries (`git`, `node`, `go`, `openssl`, `cloudflared`, etc.)
   - **Casks**: GUI applications (`docker-desktop`, `iterm2`, `claude-code`, `utm`, `bettercapture`)
   - **Language Packages**: Global Go packages and npm modules
6. **Health Check**: Executes `brew doctor` at the end to flag any system-level suggestions or warnings.

---

## Post-Installation Steps

After `install.sh` finishes:

1. **Reload Your Shell Configuration**:
   ```bash
   source ~/.zprofile
   ```
   Or simply close and reopen your Terminal / iTerm2.

2. **Grant macOS App Permissions**:
   Certain GUI applications installed via casks (such as BetterCapture, Docker Desktop, or iTerm2) will request system permissions on first launch:
   - Go to **System Settings > Privacy & Security**.
   - Review and grant necessary permissions under **Accessibility**, **Screen Recording**, and **Full Disk Access**.

3. **Log In to Command-Line Tools**:
   Authenticate any CLI tools installed from the bundle:
   ```bash
   gh auth login           # GitHub CLI
   # docker / cloudflared / etc.
   ```

---

## Ongoing Maintenance & Syncing

### Updating the `Brewfile` (From Your Source Machine)
Whenever you install new software, casks, or CLI tools on your main machine, update the repository manifest:

```bash
# Dump the updated list into Brewfile (overwriting the old one)
brew bundle dump --file=Brewfile --force

# Commit and push your changes
git add Brewfile
git commit -m "chore: update installed packages in Brewfile"
git push
```

### Pulling Updates on Your Other Mac
On your second MacBook, pull the latest changes and run `brew bundle`:

```bash
cd ~/dotfiles
git pull
brew bundle --file=Brewfile
```

### Removing Unlisted Software
If you removed formulas or casks from the `Brewfile` and want your system to uninstall anything not in the file:

```bash
brew bundle --file=Brewfile --cleanup
```

*(Add `--force` to actually perform the uninstall: `brew bundle --file=Brewfile --cleanup --force`)*

---

## Troubleshooting

- **Xcode Command Line Tools Issue**:
  If the installer gets stuck or fails to detect CLT, run:
  ```bash
  xcode-select --install
  ```
  Or reset the path:
  ```bash
  sudo xcode-select --reset
  ```

- **Homebrew Doctor Warnings**:
  If `brew doctor` reports warnings regarding unlinked formulae or directories, follow the recommendations output by brew, for example:
  ```bash
  brew doctor
  brew cleanup
  ```

- **Cask Quarantine or Installation Overrides**:
  If macOS Gatekeeper prevents an app from opening on first launch:
  ```bash
  xattr -d com.apple.quarantine /Applications/<AppName>.app
  ```
