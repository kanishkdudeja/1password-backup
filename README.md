# 1Password Backup Script

## Overview

This script is designed to automate the backup of your 1Password vaults. It interacts with your 1Password account using the 1Password Command Line Interface (CLI) to fetch and save each item from your vaults securely.

Primarily, the script uses the following 1Password CLI commands:

- `op account get`: Confirms you're signed in to your 1Password account.
- `op vault list --format json`: Lists all vaults in a JSON format.
- `op item list --vault <vaultName>`: Lists all items in a specified vault.
- `op item get <itemUUID> --format json`: Retrieves a specific item from a vault.

The script sequentially processes each vault and item, saving the data to a designated backup directory.

## Dependencies

- **Shell Compatibility:** Compatible with both Bash and Zsh shells. The script checks the shell environment and adjusts commands accordingly.
- **[1Password CLI](https://support.1password.com/command-line/):** Utilized for interacting with your 1Password account. Ensure it's installed and configured.
- **[jq](https://stedolan.github.io/jq/):** A lightweight and flexible command-line JSON processor used for parsing output from the 1Password CLI.

## Installation

1. Clone the repository:
   `git clone https://github.com/kanishkdudeja/1password-backup.git`

2. Ensure you have the necessary dependencies installed:
    - Install 1Password CLI: Instructions [here](https://support.1password.com/command-line/).
    - Install jq: Typically `sudo apt-get install jq` on Ubuntu or `brew install jq` on macOS.

## Usage

To run the script, use the following syntax:

```bash
1password-backup.sh --destination <path_to_backup_directory> [-v | --verbose]
```

### Parameters:

- `--destination`: Mandatory. Specifies the path to the directory where the backups should be stored.
- `-v` or `--verbose`: Optional. Enables verbose mode for more detailed output.

### Examples:

**Basic Usage:**

```bash
1password-backup.sh --destination /path/to/backup
```

This command will back up the 1Password vaults to the specified directory.

**Verbose Mode:**
   
```bash
1password-backup.sh --destination /path/to/backup --verbose
```

This command will do the same as above but with detailed output.

## Important Notes

- Ensure you're logged into the 1Password CLI before running the script.
- The script will exit if it encounters any errors (e.g., missing dependencies, failure to fetch data from 1Password).
- Always verify that backups are complete and valid.

## Contributing

Contributions are welcome! If you have suggestions or want to improve the script, feel free to fork the repository and submit a pull request.

---

**Disclaimer:** This script is provided "as is", without warranty of any kind. Use at your own risk.
