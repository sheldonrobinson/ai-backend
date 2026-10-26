#!/bin/bash
# Generic template-driven service installation script
# This script installs and configures a generic service using systemd
# It is designed to be used with service templates that are not specific to llama-server

set -euo pipefail

# === CONFIGURATION ===
# These defaults can be overridden by command line arguments
DEFAULT_APP_NAME="${APP_NAME:-echo}"
DEFAULT_SERVICE_NAME="${DEFAULT_APP_NAME}.service"
DEFAULT_SERVICE_USER="nobody"
DEFAULT_SERVICE_GROUP="nobody"
DEFAULT_LOG_PATH="/var/log/${DEFAULT_APP_NAME}.log"
DEFAULT_WORKING_DIR="$(mktemp -d --suffix ${DEFAULT_APP_NAME}_)"

# === FUNCTIONS ===

# Create service user and group if they don't exist
create_service_account() {
    local user="$1"
    local group="$2"
    
    echo "Creating system user: $user"
    if ! id "$user" >/dev/null 2>&1; then
        adduser --system --no-create-home --shell /bin/false "$user"
    fi
    
    echo "Creating group: $group"
    if ! getent group "$group" >/dev/null 2>&1; then
        addgroup --debug "$group"
    fi
    
    # Ensure user belongs to group
    if id -nG "$user" | grep -qw "$group"; then
        echo "User $user already belongs to group $group"
    else
        echo "Adding user $user to group $group"
        usermod -a -G "$group" "$user"
    fi
}

# Create directory with proper permissions
create_directory() {
    local dir="$1"
    local owner="$2"
    local group="$3"
    local mode="$4"
    
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
    
    chown "$owner":"$group" "$dir"
    chmod "$mode" "$dir"
}

# Configure logging
configure_logging() {
    local log_path="$1"
    local log_dir="$(dirname "$log_path")"
    
    echo "Setting up log directory: $log_dir"
    create_directory "$log_dir" "$DEFAULT_SERVICE_USER" "$DEFAULT_SERVICE_GROUP" "755"
    
    if [ ! -f "$log_path" ]; then
        touch "$log_path"
        chown "$DEFAULT_SERVICE_USER":"$DEFAULT_SERVICE_GROUP" "$log_path"
        chmod "644" "$log_path"
    fi
}

# Install generic logrotate configuration
install_logrotate() {
    local log_path="$1"
    local logrotate_dst="/etc/logrotate.d/$(basename "$log_path" | sed 's/\.log//')"
    
    # Look for a generic logrotate template
    local template_src="$(pwd)/logrotate.template"
    if [ -f "$template_src" ]; then
        echo "Installing generic logrotate configuration"
        sed "s|\/var\/log\/.*log\"|$(dirname "$log_path")\/$(basename "$log_path")\"|g" "$template_src" > "$logrotate_dst"
        chmod "644" "$logrotate_dst"
    else
        echo "Warning: No logrotate template found at $template_src"
    fi
}

# Process generic service template
process_service_template() {
    local template_src="$(pwd)/service.template"
    local template_dst="/etc/systemd/system/$DEFAULT_SERVICE_NAME"
    local env_file="$1"
    
    if [ ! -f "$template_src" ]; then
        echo "Error: Service template not found at $template_src"
        return 1
    fi
    
    # Read template and substitute variables
    local content=$(cat "$template_src")
    
    # Replace placeholders with actual values
    content="$(echo "$content" | sed "s|__SERVICE_USER__|$DEFAULT_SERVICE_USER|g")"
    content="$(echo "$content" | sed "s|__SERVICE_GROUP__|$DEFAULT_SERVICE_GROUP|g")"
    content="$(echo "$content" | sed "s|__SERVICE_NAME__|$DEFAULT_SERVICE_NAME|g")"
    content="$(echo "$content" | sed "s|__WORKING_DIR__|$DEFAULT_WORKING_DIR|g")"
    content="$(echo "$content" | sed "s|__LOG_PATH__|$__LOG_PATH__|g")"
    content="$(echo "$content" | sed "s|__ENV_FILE__|$env_file|g")"
    
    # Write processed service file
    echo "$content" > "$template_dst"
    chmod "644" "$template_dst"
    echo "Processed service file: $template_dst"
}

# Main installation function
install_service() {
    local binary_path="$1"
    
    echo "Starting generic service installation..."
    
    # Validate binary path
    if [ ! -x "$binary_path" ]; then
        echo "Error: Binary not found or not executable: $binary_path"
        exit 1
    fi
    
    # Create service account
    create_service_account "$DEFAULT_SERVICE_USER" "$DEFAULT_SERVICE_GROUP"
    
    # Configure logging
    configure_logging "$DEFAULT_LOG_PATH"
    
    # Install logrotate
    install_logrotate "$DEFAULT_LOG_PATH"
    
    # Find environment file (use existing or create from template)
    local env_file="/etc/systemd/system/${DEFAULT_SERVICE_NAME}.env"
    local env_template="/etc/systemd/system/service.env.template"
    
    if [ -f "$env_template" ]; then
        if [ ! -f "$env_file" ]; then
            echo "Creating environment file from template"
            cp "$env_template" "$env_file"
            # Apply basic defaults
            echo "SERVICE_USER=$DEFAULT_SERVICE_USER" >> "$env_file"
            echo "SERVICE_GROUP=$DEFAULT_SERVICE_GROUP" >> "$env_file"
            echo "LOG_PATH=$DEFAULT_LOG_PATH" >> "$env_file"
        fi
    fi
    
    # Process service template
    process_service_template "$env_file"
    
    # Update service file with ExecStart pointing to binary
    if [ -f "/etc/systemd/system/$DEFAULT_SERVICE_NAME" ]; then
        echo "Updating service ExecStart with binary path"
        sed -i "s|ExecStart=.*|ExecStart=$binary_path|" "/etc/systemd/system/$DEFAULT_SERVICE_NAME"
    fi
    
    # Reload systemd
    echo "Reloading systemd daemon"
    systemctl daemon-reload
    
    # Enable and start service
    echo "Enabling and starting service"
    systemctl enable "$DEFAULT_SERVICE_NAME"
    systemctl start "$DEFAULT_SERVICE_NAME"
    
    # Check status
    echo "Service status:"
    systemctl status "$DEFAULT_SERVICE_NAME" --no-pager
    
    echo "Installation completed successfully"
    echo "Service: $DEFAULT_SERVICE_NAME"
    echo "User: $DEFAULT_SERVICE_USER"
    echo "Log path: $DEFAULT_LOG_PATH"
}

# Parse command line arguments
BINARY_PATH=""
SERVICE_NAME=""
SERVICE_USER=""
SERVICE_GROUP=""
LOG_PATH=""
WORKING_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --binary)
            BINARY_PATH="$2"
            shift 2
            ;;
        --service-name)
            DEFAULT_SERVICE_NAME="$2"
            shift 2
            ;;
        --user)
            DEFAULT_SERVICE_USER="$2"
            shift 2
            ;;
        --group)
            DEFAULT_SERVICE_GROUP="$2"
            shift 2
            ;;
        --log-path)
            DEFAULT_LOG_PATH="$2"
            shift 2
            ;;
        --working-dir)
            DEFAULT_WORKING_DIR="$2"
            shift 2
            ;;
        *)
            BINARY_PATH="$1"
            ;;
    esac
    shift
    done

# Run installation
if [ -z "$BINARY_PATH" ]; then
    echo "Error: Binary path must be specified"
    echo "Usage: $0 --binary /path/to/binary [--service-name service] [--user myuser] [--group mygroup] [--log-path /var/log/myapp.log] [--working-dir /opt/myapp]"
    exit 1
fi

install_service "$BINARY_PATH"
