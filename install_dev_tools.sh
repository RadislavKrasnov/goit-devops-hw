#!/usr/bin/env bash

set -e

echo "=== Installation script (Ubuntu / Debian) ==="

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo "Updating package lists..."
sudo apt-get update -y

install_base_packages() {
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
}

install_docker() {
    if command_exists docker; then
        echo "Docker already installed. Skipping."
        return
    fi

    echo "Installing Docker..."

    install_base_packages

    sudo install -m 0755 -d /etc/apt/keyrings

    # Choose Docker repo for Ubuntu or Debian
    . /etc/os-release
    OS_ID="$ID"
    CODENAME="$VERSION_CODENAME"

    if [ "$OS_ID" != "ubuntu" ] && [ "$OS_ID" != "debian" ]; then
        echo "Unsupported distro for this script: $OS_ID"
        exit 1
    fi

    # Docker GPG key
    if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
        curl -fsSL "https://download.docker.com/linux/${OS_ID}/gpg" \
            | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
    fi

    # Docker repo list
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        echo "Adding Docker apt repository..."
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
          https://download.docker.com/linux/${OS_ID} \
          ${CODENAME} stable" \
          | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

        echo "Updating package lists after adding Docker repo..."
        sudo apt-get update -y
    fi

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
}

install_docker_compose() {
    # Compose plugin check (modern): "docker compose"
    if docker compose version >/dev/null 2>&1; then
        echo "Docker Compose already installed. Skipping."
        return
    fi

    echo "Installing Docker Compose plugin..."
    sudo apt-get install -y docker-compose-plugin
}

install_python() {
    if command_exists python3; then
        PY_OK=$(python3 - <<'EOF'
import sys
print(sys.version_info >= (3,9))
EOF
)
        if [ "$PY_OK" = "True" ]; then
            echo "Python 3.9+ already installed. Skipping."
            return
        fi
    fi

    echo "Installing Python 3 and pip..."
    sudo apt-get install -y python3 python3-pip
}

install_django() {
    # Install Django via pip in a venv to avoid PEP 668 restrictions
    VENV_DIR="$HOME/django_venv"

    if [ -x "$VENV_DIR/bin/python" ] && "$VENV_DIR/bin/python" -m django --version >/dev/null 2>&1; then
        echo "Django already installed in venv ($VENV_DIR). Skipping."
        return
    fi

    echo "Installing Django via pip in venv ($VENV_DIR)..."
    sudo apt-get install -y python3-venv

    python3 -m venv "$VENV_DIR"
    "$VENV_DIR/bin/python" -m pip install --upgrade pip
    "$VENV_DIR/bin/python" -m pip install django

    echo "Django installed in venv."
    echo "To use it:"
    echo "  source $VENV_DIR/bin/activate"
    echo "  django-admin --version"
}

install_docker
install_docker_compose
install_python
install_django

echo "=== Installation completed successfully ==="

