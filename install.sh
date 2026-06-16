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

# Create a models.ini with example entries if it does not exist
MODELS_INI="$HOME/.konnek/llamacpp/models.ini"
if [ ! -f "$MODELS_INI" ]; then
  cat > "$MODELS_INI" <<'EOF'
# Llama.C++ models configuration
# Define models as key=value pairs: name=/absolute/path/to/ggml-model.bin
# Example:
# gpt4all=/home/user/.local/share/llama/models/gpt4all.bin

# Add your models below

EOF
  echo "Created $MODELS_INI"
else
  echo "$MODELS_INI already exists; leaving unchanged."
fi

# Set LLAMA_ARG_HOST=localhost in common user shell profiles if not present
for profile in "$HOME/.bashrc" "$HOME/.bash_profile" "$HOME/.zshrc"; do
  if [ -f "$profile" ]; then
    if ! grep -q '^export LLAMA_ARG_HOST=localhost$' "$profile"; then
      echo "export LLAMA_ARG_HOST=localhost" >> "$profile"
      echo "Added LLAMA_ARG_HOST to $profile"
    fi
  fi
done

# Also export for current session
export LLAMA_ARG_HOST=localhost

echo "Installation completed successfully."
