#!/usr/bin/env bash
#
# recall.sh
# Build, run, edit, and optionally persist named multi-step command sequences
# for your current shell session.
#
# Usage:
#   source recall.sh
#
# Then use: makecmd, editcmd, savecmd, forgetcmds, listcmds

_MAKECMD_LIST=()
declare -A _MAKECMD_CMDS   # name -> newline-separated commands

makecmd() {
  read -p "Name this command set: " name

  if [[ -z "$name" ]]; then
    echo "Name cannot be empty."
    return 1
  fi

  local cmds=()
  local i=1
  echo "Enter commands one by one. Press Enter on empty line to finish."
  while true; do
    read -p "Command $i: " line
    [[ -z "$line" ]] && break
    cmds+=("$line")
    ((i++))
  done

  if [[ ${#cmds[@]} -eq 0 ]]; then
    echo "No commands entered. Nothing saved."
    return 1
  fi

  local joined
  joined=$(printf '%s\n' "${cmds[@]}")
  eval "$name() {
$joined
  }"

  _MAKECMD_CMDS["$name"]="$joined"
  _MAKECMD_LIST+=("$name")
  echo "Saved. Run '$name' anytime this session to execute all ${#cmds[@]} command(s)."

  read -p "Make this permanent too? (y/n): " perm
  if [[ "$perm" == "y" ]]; then
    _savecmd_to_file "$name"
  fi
}

listcmds() {
  if [[ ${#_MAKECMD_LIST[@]} -eq 0 ]]; then
    echo "No saved command sets yet."
    return 1
  fi
  echo "Available command sets:"
  local i=1
  for c in "${_MAKECMD_LIST[@]}"; do
    echo "  $i) $c"
    ((i++))
  done
}

_select_cmdset() {
  # Echoes the resolved name, or nothing if invalid. Caller checks $?.
  local choice="$1"
  if [[ "$choice" =~ ^[0-9]+$ ]]; then
    echo "${_MAKECMD_LIST[$((choice-1))]}"
  else
    echo "$choice"
  fi
}

editcmd() {
  if [[ ${#_MAKECMD_LIST[@]} -eq 0 ]]; then
    echo "No saved command sets yet."
    return 1
  fi

  listcmds
  read -p "Which one do you want to edit (name or number)? " choice
  local name
  name=$(_select_cmdset "$choice")

  if [[ -z "${_MAKECMD_CMDS[$name]}" ]]; then
    echo "No saved command set called '$name'."
    return 1
  fi

  echo "Current commands in '$name':"
  local old_cmds=()
  local idx=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "  $idx) $line"
    old_cmds+=("$line")
    ((idx++))
  done <<< "${_MAKECMD_CMDS[$name]}"

  echo ""
  echo "Options: (e)dit a line, (a)dd a line, (d)elete a line, (r)ewrite all, (c)ancel"
  read -p "Choice: " action

  case "$action" in
    e)
      read -p "Which line number to edit? " n
      read -p "New text for line $n: " newline
      old_cmds[$((n-1))]="$newline"
      ;;
    a)
      read -p "New command to add: " newline
      old_cmds+=("$newline")
      ;;
    d)
      read -p "Which line number to delete? " n
      unset 'old_cmds[$((n-1))]'
      old_cmds=("${old_cmds[@]}")
      ;;
    r)
      old_cmds=()
      local i=1
      echo "Re-enter all commands. Press Enter on empty line to finish."
      while true; do
        read -p "Command $i: " line
        [[ -z "$line" ]] && break
        old_cmds+=("$line")
        ((i++))
      done
      ;;
    c)
      echo "Cancelled."
      return 0
      ;;
    *)
      echo "Invalid choice."
      return 1
      ;;
  esac

  local joined
  joined=$(printf '%s\n' "${old_cmds[@]}")
  eval "$name() {
$joined
  }"
  _MAKECMD_CMDS["$name"]="$joined"
  echo "Updated '$name'."

  read -p "Save these changes permanently too? (y/n): " perm
  if [[ "$perm" == "y" ]]; then
    _savecmd_to_file "$name"
  fi
}

_savecmd_to_file() {
  local name="$1"
  local rcfile="${HOME}/.bashrc"
  [[ -n "$ZSH_VERSION" ]] && rcfile="${HOME}/.zshrc"

  echo ""
  echo "Where do you want to save '$name'?"
  echo "  1) $rcfile (auto-loads in every new terminal)"
  echo "  2) A custom file path"
  read -p "Choice: " dest

  local target
  if [[ "$dest" == "1" ]]; then
    target="$rcfile"
  elif [[ "$dest" == "2" ]]; then
    read -p "Enter file path: " target
    target="${target/#\~/$HOME}"
  else
    echo "Invalid choice. Skipping permanent save."
    return 1
  fi

  {
    echo ""
    echo "# --- saved by recall on $(date) ---"
    echo "$name() {"
    echo "${_MAKECMD_CMDS[$name]}"
    echo "}"
  } >> "$target"

  echo "Saved '$name' permanently to $target"
  if [[ "$target" == "$rcfile" ]]; then
    echo "It will be available in all new terminals from now on."
  else
    echo "To use it in future sessions, run: source $target"
  fi
}

savecmd() {
  if [[ ${#_MAKECMD_LIST[@]} -eq 0 ]]; then
    echo "No saved command sets yet."
    return 1
  fi

  listcmds
  read -p "Which one do you want to make permanent (name or number)? " choice
  local name
  name=$(_select_cmdset "$choice")

  if [[ -z "${_MAKECMD_CMDS[$name]}" ]]; then
    echo "No saved command set called '$name'."
    return 1
  fi

  _savecmd_to_file "$name"
}

forgetcmds() {
  if [[ ${#_MAKECMD_LIST[@]} -eq 0 ]]; then
    echo "No saved command sets yet."
    return 1
  fi

  local keep=()
  for c in "${_MAKECMD_LIST[@]}"; do
    read -p "Delete '$c'? (y/n): " ans
    if [[ "$ans" == "y" ]]; then
      unset -f "$c"
      unset "_MAKECMD_CMDS[$c]"
      echo "Deleted $c"
    else
      keep+=("$c")
    fi
  done
  _MAKECMD_LIST=("${keep[@]}")
}
