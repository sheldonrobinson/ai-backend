#!/usr/bin/env bash
# start-all.sh
# Starts Llama.C++ HTTP server, agentgateway, and MCPJungle on Linux/macOS.
# Default behavior runs components in background (hidden). Use --visible to open terminals if available.

set -euo pipefail

VISIBLE=0
for arg in "$@"; do
  case "$arg" in
    --visible|-v) VISIBLE=1 ;;
    *) ;;
  esac
done

# Per-user install and log locations
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/Konnek/AI-Backend"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-backend-logs"
mkdir -p "$INSTALL_DIR" "$LOG_DIR"

# Logging / rotation settings
RETENTION_DAYS=7
MAX_LOG_SIZE_MB=10
COMPRESS_AFTER_DAYS=1
MAX_LOG_BYTES=$((MAX_LOG_SIZE_MB * 1024 * 1024))

compress_log_file() {
  local path="$1"
  if [ -f "$path" ]; then
    gzip -9 -c "$path" > "${path}.gz" && : > "$path"
  fi
}

rotate_log_if_needed() {
  local logfile="$1"
  if [ -f "$logfile" ]; then
    local size
    size=$(stat -c%s "$logfile" 2>/dev/null || stat -f%z "$logfile" 2>/dev/null || echo 0)
    if [ "$size" -ge "$MAX_LOG_BYTES" ]; then
      local timestamp
      timestamp=$(date +%Y%m%d%H%M%S)
      mv "$logfile" "${logfile}.${timestamp}"
      gzip -9 "${logfile}.${timestamp}" || true
      echo "Rotated and compressed $logfile -> ${logfile}.${timestamp}.gz"
    fi
  fi
}

# Compress raw logs older than COMPRESS_AFTER_DAYS
if [ "$COMPRESS_AFTER_DAYS" -ge 0 ]; then
  find "$LOG_DIR" -type f -name "*.log" -mtime +$COMPRESS_AFTER_DAYS -print0 2>/dev/null | xargs -0 -r -n1 gzip -9 || true
fi

# Remove archived files older than retention
find "$LOG_DIR" -type f -mtime +$RETENTION_DAYS -print0 2>/dev/null | xargs -0 -r rm -f || true

# Terminal opener function (tries common terminals)
open_in_terminal() {
  local cmd="$1"
  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal -- bash -ic "$cmd; exec bash" &
    return 0
  fi
  if command -v konsole >/dev/null 2>&1; then
    konsole -e bash -ic "$cmd; exec bash" &
    return 0
  fi
  if command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal -e "bash -ic '$cmd; exec bash'" &
    return 0
  fi
  if command -v xterm >/dev/null 2>&1; then
    xterm -e "bash -ic '$cmd; exec bash'" &
    return 0
  fi
  # macOS Terminal
  if [ "$(uname)" = "Darwin" ]; then
    osascript <<APPLE
tell application "Terminal"
    do script "$cmd"
    activate
end tell
APPLE
    return 0
  fi
  return 1
}

find_exe() {
  local names=("$@")
  for n in "${names[@]}"; do
    if command -v "$n" >/dev/null 2>&1; then
      command -v "$n"; return 0
    fi
  done
  # Common install locations
  for n in "${names[@]}"; do
    for p in "$INSTALL_DIR/$n" "$INSTALL_DIR/bin/$n" "/usr/local/bin/$n" "/usr/bin/$n" "$HOME/.local/bin/$n"; do
      if [ -x "$p" ]; then
        printf '%s' "$p"; return 0
      fi
      if [ -x "$p".exe ] 2>/dev/null; then
        printf '%s' "$p.exe"; return 0
      fi
    done
  done
  return 1
}

start_component() {
  local name="$1"; shift
  local -n exes=$1; shift
  local args="$*"

  echo "Starting $name..."
  local exe
  exe=$(find_exe "${exes[@]}" ) || true
  if [ -z "$exe" ]; then
    echo "Warning: could not find executable for $name (tried: ${exes[*]}). Skipping." >&2
    return
  fi

  local safe_name
  safe_name=$(echo "$name" | sed 's/[^a-zA-Z0-9]/_/g')
  local datepart
  datepart=$(date +%F)
  local logfile
  logfile="$LOG_DIR/${safe_name}-${datepart}.log"

  rotate_log_if_needed "$logfile"

  if [ "$VISIBLE" -eq 1 ]; then
    # open in terminal if possible, else run in background but not hidden
    local cmd
    cmd="\"$exe\" $args"
    if open_in_terminal "$cmd"; then
      echo "$name launched in terminal (executable: $exe)"
    else
      nohup "$exe" $args >> "$logfile" 2>&1 &
      disown
      echo "$name started (background, no terminal) (executable: $exe), logging: $logfile"
    fi
  else
    # hidden/background using nohup
    nohup "$exe" $args >> "$logfile" 2>&1 &
    disown
    echo "$name started (hidden/background) (executable: $exe), logging: $logfile"
  fi
}

# Components list (name, array of possible exe names, args)
llama_exes=(llama-server llama-server-http llama)
agent_exes=(agentgateway agentgateway-server)
mcp_exes=(mcpjungle mcpjungle-server)

start_component "Llama.C++ HTTP Server" llama_exes -- --http --port 8080
start_component "agentgateway LLM proxy" agent_exes
start_component "MCPJungle MCP gateway" mcp_exes

echo "All start requests issued. Logs: $LOG_DIR"

exit 0
