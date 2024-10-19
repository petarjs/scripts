#!/bin/bash

# Path to the file where the current key name will be stored
CURRENT_KEY_FILE="$HOME/.current_ssh_key"

# Function to display the current SSH key
display_current_key() {
  if [ -f "$CURRENT_KEY_FILE" ]; then
    echo "Currently loaded SSH key: $(cat $CURRENT_KEY_FILE)"
    ssh-add -l
  else
    echo "No SSH key has been set through this script."
  fi
}

# Function to switch SSH keys based on alias
switch_key() {
  local key_alias=$1
  local key_path

  case $key_alias in
    "vx")
      key_path="$HOME/.ssh/vx"
      ;;
    "q")
      key_path="$HOME/.ssh/git.quantox.tech"
      ;;
    "p")
      key_path="$HOME/.ssh/petarjs"
      ;;
    *)
      key_path="$HOME/.ssh/$key_alias"
      ;;
  esac

  if [ -f "$key_path" ]; then
    echo "Switching to SSH key: $key_alias"
    ssh-add -D
    ssh-add "$key_path"
    if [ $? -eq 0 ]; then
      echo "Successfully switched to SSH key: $key_alias"
      # Write the alias or filename to the file
      echo "$key_alias" > "$CURRENT_KEY_FILE"
      display_current_key
    else
      echo "Failed to add SSH key: $key_alias"
    fi
  else
    echo "SSH key file $key_path does not exist."
  fi
}

# Check if any argument is provided
if [ $# -eq 0 ]; then
  display_current_key
else
  switch_key "$1"
fi

