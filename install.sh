#!/bin/bash
set -e

echo "Installing AI Backend components for Linux/MacOS..."

if ! command -v brew &> /dev/null
then
    echo "Homebrew not found. Please install it first from https://brew.sh/"
    exit 1
fi

brew install make
brew install python@3.14
brew install pnpm@11
brew install node@24
brew install wget
brew install ninja
brew install git
brew install git-lfs
brew install cmake
brew install xmake
brew install llama.cpp

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install pipx
    pipx ensurepath
else
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
fi

pipx install sugarai

echo "Installing agentgateway..."
curl -sL https://agentgateway.dev/install | bash

echo "Installing mcpjungle..."
brew install mcpjungle/mcpjungle/mcpjungle

echo "Installing goose-cli..."
curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

echo "Installing Goose Desktop..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install --cask block-goose
else
    echo "Fetching latest Goose Desktop release for Linux..."
    LATEST_API="https://api.github.com/repos/aaif-goose/goose/releases/latest"
    
    if command -v dpkg &> /dev/null; then
        ASSET_URL=$(curl -s $LATEST_API | grep "browser_download_url.*\.deb" | cut -d '"' -f 4 | head -n 1)
        if [ -n "$ASSET_URL" ]; then
            echo "Downloading $ASSET_URL..."
            wget -qO /tmp/goose.deb "$ASSET_URL"
            sudo dpkg -i /tmp/goose.deb || sudo apt-get install -f -y
        else
            echo "Could not find .deb asset for Goose Desktop."
        fi
    elif command -v rpm &> /dev/null; then
        ASSET_URL=$(curl -s $LATEST_API | grep "browser_download_url.*\.rpm" | cut -d '"' -f 4 | head -n 1)
        if [ -n "$ASSET_URL" ]; then
            echo "Downloading $ASSET_URL..."
            wget -qO /tmp/goose.rpm "$ASSET_URL"
            sudo rpm -i /tmp/goose.rpm || sudo dnf install -y /tmp/goose.rpm
        else
            echo "Could not find .rpm asset for Goose Desktop."
        fi
    else
        echo "Unsupported Linux package manager. Please install Goose Desktop manually."
    fi
fi

echo "Setting up local-mcp configuration..."
if command -v npx &> /dev/null; then
    export LMCP_REF="67df72f4"
    npx -y local-mcp@latest setup || echo "local-mcp setup failed, but continuing..."
else
    echo "npx not found, skipping local-mcp setup."
fi

# Post-install configuration for Llama.C++
echo "Configuring Llama.C++ post-install..."
# Ensure user config directory
mkdir -p "$HOME/.konnek/llamacpp"

# Download models.ini if not present
MODELS_INI="$HOME/.konnek/llamacpp/models.ini"
MODELS_URL_RAW="https://raw.githubusercontent.com/sheldonrobinson/llamacpp.install/main/installer/config/models.ini"
if [ ! -f "$MODELS_INI" ]; then
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$MODELS_URL_RAW" -o "$MODELS_INI" && echo "Downloaded models.ini to $MODELS_INI"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$MODELS_INI" "$MODELS_URL_RAW" && echo "Downloaded models.ini to $MODELS_INI"
  else
    # Fallback: create template
    cat > "$MODELS_INI" <<'EOF'
# Llama.C++ models configuration
# Define models as key=value pairs: name=/absolute/path/to/ggml-model.bin
# Example:
# gpt4all=/home/user/.local/share/llama/models/gpt4all.bin

# Add your models below

EOF
    echo "Created template $MODELS_INI (curl/wget not available to download default file)"
  fi
else
  echo "$MODELS_INI already exists; leaving unchanged."
fi

# Set LLAMA_* environment variables and add to user shells if not present
LLAMA_HOST_VAL="localhost"
LLAMA_PORT_VAL="11434"
LLAMA_TOOLS_VAL="all"
LLAMA_UI_MCP_PROXY_VAL="true"
LLAMA_MODELS_PRESET_VAL="$HOME/.konnek/llamacpp/models.ini"

for profile in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [ -f "$profile" ]; then
    grep -qxF "export LLAMA_ARG_HOST=$LLAMA_HOST_VAL" "$profile" || echo "export LLAMA_ARG_HOST=$LLAMA_HOST_VAL" >> "$profile"
    grep -qxF "export LLAMA_ARG_PORT=$LLAMA_PORT_VAL" "$profile" || echo "export LLAMA_ARG_PORT=$LLAMA_PORT_VAL" >> "$profile"
    grep -qxF "export LLAMA_ARG_TOOLS=$LLAMA_TOOLS_VAL" "$profile" || echo "export LLAMA_ARG_TOOLS=$LLAMA_TOOLS_VAL" >> "$profile"
    grep -qxF "export LLAMA_ARG_UI_MCP_PROXY=$LLAMA_UI_MCP_PROXY_VAL" "$profile" || echo "export LLAMA_ARG_UI_MCP_PROXY=$LLAMA_UI_MCP_PROXY_VAL" >> "$profile"
    grep -qxF "export LLAMA_ARG_MODELS_PRESET=$LLAMA_MODELS_PRESET_VAL" "$profile" || echo "export LLAMA_ARG_MODELS_PRESET=$LLAMA_MODELS_PRESET_VAL" >> "$profile"
  fi
done

# Export for current session
export LLAMA_ARG_HOST="$LLAMA_HOST_VAL"
export LLAMA_ARG_PORT="$LLAMA_PORT_VAL"
export LLAMA_ARG_TOOLS="$LLAMA_TOOLS_VAL"
export LLAMA_ARG_UI_MCP_PROXY="$LLAMA_UI_MCP_PROXY_VAL"
export LLAMA_ARG_MODELS_PRESET="$LLAMA_MODELS_PRESET_VAL"

# Post-install configuration for agentgateway
echo "Configuring agentgateway post-install..."
mkdir -p "$HOME/.konnek/agentgateway"
GATEWAY_YML="$HOME/.konnek/agentgateway/gateway.yml"
GATEWAY_URL_RAW="https://raw.githubusercontent.com/sheldonrobinson/agentgateway.install/main/installer/config/gateway.yml"
if [ ! -f "$GATEWAY_YML" ]; then
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$GATEWAY_URL_RAW" -o "$GATEWAY_YML" && echo "Downloaded gateway.yml to $GATEWAY_YML"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$GATEWAY_YML" "$GATEWAY_URL_RAW" && echo "Downloaded gateway.yml to $GATEWAY_YML"
  else
    echo "Warning: curl/wget not available; please place gateway.yml at $GATEWAY_YML"
  fi
else
  echo "$GATEWAY_YML already exists; leaving unchanged."
fi

# Export LOCAL_XDS_PATH in user shells
for profile in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [ -f "$profile" ]; then
    grep -qxF "export LOCAL_XDS_PATH=$GATEWAY_YML" "$profile" || echo "export LOCAL_XDS_PATH=$GATEWAY_YML" >> "$profile"
  fi
done
export LOCAL_XDS_PATH="$GATEWAY_YML"

# Post-install configuration for MCPJungle
echo "Configuring MCPJungle post-install..."
mkdir -p "$HOME/.konnek/mcpjungle"
MCP_DB="$HOME/.konnek/mcpjungle/mcpjungle.db"
MCP_DB_URL_RAW="https://raw.githubusercontent.com/sheldonrobinson/mcpjungle.install/main/installer/config/mcpjungle.db"
if [ ! -f "$MCP_DB" ]; then
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$MCP_DB_URL_RAW" -o "$MCP_DB" && echo "Downloaded mcpjungle.db to $MCP_DB"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$MCP_DB" "$MCP_DB_URL_RAW" && echo "Downloaded mcpjungle.db to $MCP_DB"
  else
    echo "Warning: curl/wget not available; please place mcpjungle.db at $MCP_DB"
  fi
else
  echo "$MCP_DB already exists; leaving unchanged."
fi

# Record recommended MCPJungle args in a small wrapper file for start scripts
MCP_ARGS_FILE="$HOME/.konnek/mcpjungle/args.txt"
echo "--port 9000 --sqlite-db-path $MCP_DB" > "$MCP_ARGS_FILE"

# Also export a convenience variable for start scripts
for profile in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [ -f "$profile" ]; then
    grep -qxF "export MCPJUNGLE_ARGS='--sqlite-db-path $MCP_DB'" "$profile" || echo "export MCPJUNGLE_ARGS='--sqlite-db-path $MCP_DB'" >> "$profile"
  fi
done
export MCPJUNGLE_ARGS="--sqlite-db-path $MCP_DB"


echo "Installation completed successfully."
