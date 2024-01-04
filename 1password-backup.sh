#!/bin/bash

# Exit script if an undefined variable is used, preventing unexpected behavior.
set -u

# Exit immediately if a command exits with a non-zero status, ensuring errors are handled promptly.
set -e

# Ensure a pipeline returns a failure status if any command in the pipeline fails, enhancing error detection.
set -o pipefail

# Function to print error messages in red
echo_error() {
    local RED="\033[0;31m"
    local RESET="\033[0m"
    echo -e "${RED}Error: $1${RESET}"
}

# Function to print informational messages in blue
echo_info() {
    local BLUE="\033[0;34m"
    local RESET="\033[0m"
    if [ "$verbose" = true ]; then
      echo -e "${BLUE}Info: $1${RESET}"
    fi
}

# Function to print success messages in green
echo_success() {
    local GREEN="\033[0;32m"
    local RESET="\033[0m"
    echo -e "${GREEN}Success: $1${RESET}"
}

verbose=false
tmp_dir=$(pwd)
destination_dir=""

# Loop through arguments and process them
while [ "${1:-default}" != "default" ]; do
    case $1 in
        -destination | --destination )        shift
                             destination_dir=$1
                             ;;
        -v | --verbose )    verbose=true
                                    ;;
        * )                  echo_error "Invalid argument: $1"
                             exit 1
    esac
    shift
done

if [[ -z "$destination_dir" ]]; then
    echo_error "The script needs the --destination command line argument which denotes the path to store the backup in. Exiting."
    exit 1
fi

if [ ! -d "$destination_dir" ]; then
    echo_error "The directory $destination_dir does not exist. Exiting."
    exit 1
fi

echo_info "Destination Directory passed in as: $destination_dir"

# Remove the last character from the destination directory if it is a backslash
destination_dir=$(echo "$destination_dir" | sed 's/\/$//')

if ! command -v op >/dev/null 2>&1; then
    echo_error "op (1Password CLI) is not installed. Exiting."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo_error "jq is not installed. Exiting."
    exit 1
fi

op account get > /dev/null
exit_code=$?

if [ $exit_code -ne 0 ]; then
  echo_error "The command 'op account get' failed with exit code $exit_code. Please make sure you are signed in to 1Password CLI."
fi

echo_info "Attempting to fetch vaults"

# Check and use shell-specific features
# Assign command output to an array, splitting on newlines
if [ -n "${BASH_VERSION-}" ]; then
    readarray -t vaults < <(op vault list --format json | jq -r '.[] | .name')
elif [ -n "${ZSH_VERSION-}" ]; then
    vaults=("${(@f)$(op vault list --format json | jq -r '.[] | .name')}")
else
    echo_error "This script only supports the Bash and Zsh shells. Exiting."
fi

echo_info "Vaults fetched: $(printf "%s, " "${vaults[@]}" | sed 's/, $//')"

current_time=$(date '+%Y-%m-%d-%H-%M-%S')
backup_dir="$current_time"
echo_info "Attempting to create backup directory: $tmp_dir/$backup_dir"

cd "$tmp_dir" || exit
mkdir "$backup_dir"

if [ -d "$backup_dir" ]; then
  echo_info "Backup Directory successfully created: $tmp_dir/$backup_dir"
else
  echo_error "Backup Directory $tmp_dir/$backup_dir could not be created. Exiting."
  exit 1
fi

## loop through the vaults array
for vault in "${vaults[@]}"
do
  if [ "$vault" = "Shared" ]; then
      # Skip this iteration.
      continue
  fi
  if [ "$vault" = "Automattic" ]; then
        # Skip this iteration.
        continue
    fi
   echo_info "Changing directory to backup directory: $backup_dir"
   cd "$tmp_dir/$backup_dir" || exit

   echo_info "Creating directory for vault: $vault"
   mkdir "$vault"

   if [ -d "$tmp_dir/$backup_dir/$vault" ]; then
     echo_info "Vault Directory successfully created: $tmp_dir/$backup_dir/$vault"
   else
     echo_error "Vault Directory $tmp_dir/$backup_dir/$vault could not be created. Exiting."
     exit 1
   fi

   echo_info "Changing directory to vault: $tmp_dir/$backup_dir/$vault"
   cd "$tmp_dir/$backup_dir/$vault" || exit

   echo_info "Fetching items for vault: $vault"

   for uuid in $(op item list --vault "$vault" | awk 'NR > 1 {print $1}'); do
      echo_info "Fetching item for vault $vault with UUID: $uuid"
      touch "$uuid".json
      op item get "$uuid" --format json > "$uuid".json
      echo_info "Saved information for item with UUID $uuid in: $tmp_dir/$backup_dir/$vault/$uuid.json"
   done
done

echo_info "Moving backup directory $tmp_dir/$backup_dir/ to $destination_dir"
mv "$tmp_dir/$backup_dir" "$destination_dir/"

echo_success "1Password vaults successfully backed up in $destination_dir/$backup_dir/"