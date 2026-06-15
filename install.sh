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

curl -sL https://agentgateway.dev/install | bash
brew install mcpjungle/mcpjungle/mcpjungle
curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | CONFIGURE=false bash

if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install --cask block-goose
else
    echo "For Linux, please download the appropriate package from https://github.com/aaif-goose/goose/releases"
fi

echo "Installation completed successfully."
