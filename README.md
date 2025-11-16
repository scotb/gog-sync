# GOG Sync Scripts

This repository contains scripts to automate downloading and updating your GOG.com game library using `lgogdownloader` in a Docker container. The primary purpose is to archive your GOG games to a safe backup location, ensuring you have a personal copy of your purchased games. 

The Docker image will automatically download and build the latest version of `lgogdownloader` during the build process. Scripts are provided for both PowerShell (Windows) and Bash (Linux/macOS/WSL).

## Prerequisites

- [Docker](https://www.docker.com/) installed and running
- [docker-compose](https://docs.docker.com/compose/) installed
- [lgogdownloader](https://github.com/Sude-/lgogdownloader) configured in your Docker image
- A valid GOG account and `lgogdownloader` config

---

1. **Clone this repository:**
```sh
   git clone https://github.com/scotb/gog-sync.git
   cd gog-sync
```

2. **Edit paths as needed:**
   - Update any hardcoded paths in the scripts (e.g., `C:\gog-archive`, `~/gog-archive`) to match your system.
   - Ensure your `docker-compose.yaml` volume mappings match your desired download and config locations.

3. **Build the Docker image (if needed):**
```sh
   docker-compose build
```

## Authentication & Credentials

Before you can download or update your games, you must log in to your GOG account using `lgogdownloader`. The login process will prompt you for your GOG credentials and store them securely in a configuration file.

**Credential Storage:**

- The credentials and configuration are stored in the file mapped by the `volumes` section of your `docker-compose.yaml` file:
   - Example:
   ```yaml
      - C:/Users/youruser/.config/lgogdownloader:/root/.config/lgogdownloader
   ```
   - This ensures your login session and settings persist across container runs and are not lost when the container is removed.


**To log in (PowerShell):**

1. Run your sync script with the `-Tty` flag to ensure you get an interactive login prompt. For example:
```powershell
   ./gog-sync.ps1 -Tty -Download
```
   or, for repair:
```powershell
   ./gog-sync.ps1 -Tty -Download -Repair
```
2. If you are not already logged in, `lgogdownloader` will prompt you for your GOG credentials and any required two-factor authentication.
3. Your credentials will be saved in the mapped config file for future runs.

**To log in (Bash/Linux):**

1. Run your sync script with the `--tty` flag to ensure you get an interactive login prompt. For example:
```bash
   ./gog-sync.sh --tty --download
```
   or, for repair:
```bash
   ./gog-sync.sh --tty --download --repair
```
2. If you are not already logged in, `lgogdownloader` will prompt you for your GOG credentials and any required two-factor authentication.
3. Your credentials will be saved in the mapped config file for future runs.

> **Note:** Once your credentials are cached in the mapped config file, you no longer need to use the `--tty` flag for automated Bash/Linux runs. Only use it when you need to log in or re-authenticate.

## Usage

### PowerShell (Windows)

Run from the project directory:


```powershell
# Quick update check - lists games with updates available
./gog-sync.ps1
#   → Only lists games with updates available (fast, targeted)

# List all games in your GOG library
./gog-sync.ps1 -ListAll
#   → Lists all games in your GOG library

# Download only updated games (recommended for regular syncs)
./gog-sync.ps1 -Download
#   → Only downloads updates for games that need them (fast, targeted)

# Download ALL games and components (complete archive)
./gog-sync.ps1 -DownloadAll
#   → Downloads everything in your GOG library (slow, full backup)

# Repair/verify all downloaded files (checks integrity, redownloads if needed)
./gog-sync.ps1 -Repair
#   → Checks all files and redownloads any that are missing/corrupted (full verification)

# Show all output (disables ERROR/WARNING filter)
./gog-sync.ps1 -ShowAllOutput
#   → Shows all output, including progress bars and ANSI codes

# Verbose log (filters out ANSI/gibberish, keeps progress, filenames, errors, warnings)
./gog-sync.ps1 -VerboseLog
#   → Shows only meaningful progress, filenames, errors, and warnings

# Add -Tty if you need an interactive TTY for debugging
./gog-sync.ps1 -Download -Tty
#   → Use for interactive login or debugging
```

### Bash (Linux/macOS/WSL)

Run from the project directory:

```bash
# Quick update check - lists games with updates available
./gog-sync.sh
#   → Only lists games with updates available (fast, targeted)

# List all games in your GOG library
./gog-sync.sh --list-all
#   → Lists all games in your GOG library

# Download only updated games (recommended for regular syncs)
./gog-sync.sh --download
#   → Only downloads updates for games that need them (fast, targeted)

# Download ALL games and components (complete archive)
./gog-sync.sh --download-all
#   → Downloads everything in your GOG library (slow, full backup)

# Repair/verify all downloaded files (checks integrity, redownloads if needed)
./gog-sync.sh --repair
#   → Checks all files and redownloads any that are missing/corrupted (full verification)

# Show all output (disables ERROR/WARNING filter)
./gog-sync.sh --show-all-output
#   → Shows all output, including progress bars and ANSI codes

# Verbose log (filters out ANSI/gibberish, keeps progress, filenames, errors, warnings)
./gog-sync.sh --verbose-log
#   → Shows only meaningful progress, filenames, errors, and warnings

# Add --tty if you need an interactive TTY for debugging
./gog-sync.sh --download --tty
#   → Use for interactive login or debugging
```

---

## Game Name Filtering


You can filter downloads, updates, or listings to a specific game using the game name flag. By default, partial (contains) matching is used. For exact matching, add the `-ExactMatch` (PowerShell) or `--exact-match` (Bash) flag.

- **PowerShell:** Use `-GameName "name"` (e.g., `./gog-sync.ps1 -Download -GameName "witcher"`)
   - Add `-ExactMatch` for an exact match (e.g., `./gog-sync.ps1 -Download -GameName "witcher" -ExactMatch`)
- **Bash:** Use `--game-name "name"` (e.g., `./gog-sync.sh --download --game-name "witcher"`)
   - Add `--exact-match` for an exact match (e.g., `./gog-sync.sh --download --game-name "witcher" --exact-match`)

**Examples:**

```powershell
# Partial match (default): matches any game containing "azure"
./gog-sync.ps1 -ListAll -GameName "azure"
# Exact match: matches only a game named exactly "azure"
./gog-sync.ps1 -ListAll -GameName "azure" -ExactMatch
```

```bash
# Partial match (default): matches any game containing "azure"
./gog-sync.sh --list-all --game-name "azure"
# Exact match: matches only a game named exactly "azure"
./gog-sync.sh --list-all --game-name "azure" --exact-match
```

---
- Start and end times, as well as elapsed time, are logged for each run.
- The full command being executed is logged at the start of each run for debugging purposes.

---

## Scheduling

- **Windows:** Use Task Scheduler to run the PowerShell script on a schedule.
- **Linux:** Use `cron` to schedule the Bash script.

---


## Customization


- **GameName/ExactMatch parameters:**
   - PowerShell: Use `-GameName "game_name"` for partial match, add `-ExactMatch` for exact match.
   - Bash: Use `--game-name "game_name"` for partial match, add `--exact-match` for exact match.

- Edit the scripts to change log file location, thread count, or other options as needed.
- Update the `docker-compose.yaml` to match your folder structure and preferences.

---

## Troubleshooting

- Ensure Docker and docker-compose are running and accessible from your shell.
- Make sure your user has permission to write to the log file and mapped volumes.
- If you see ownership or permission errors, run your shell as Administrator (Windows) or with `sudo` (Linux).

---

## License

MIT License
