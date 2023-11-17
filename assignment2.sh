#!/bin/bash

# Function to display messages in a human-friendly way
function log {
  echo -e "\n### $1 ###\n"
}

# Function to check if a package is installed and install if not
function ensure_package_installed {
  package_name=$1
  if ! dpkg -l $package_name &> /dev/null; then
    log "Installing $package_name..."
    apt-get -y install $package_name
  else
    log "$package_name is already installed."
  fi
}

# Function to configure the network using netplan
function configure_network {
  log "Configuring network..."
  cat <<EOF > /etc/netplan/01-network-manager-all.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.1
      nameservers:
        addresses: [192.168.16.1]
        search: [home.arpa, localdomain]
EOF
  log "Applying network configuration..."
  netplan apply
}

# Function to configure firewall using ufw
function configure_firewall {
  log "Configuring firewall..."
  ufw allow 22     # SSH
  ufw allow 80     # HTTP
  ufw allow 443    # HTTPS
  ufw allow 3128   # Squid Proxy
  ufw --force enable
}

# Function to create user accounts and configure SSH key authentication
function create_users {
  log "Creating user accounts..."
  users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
  for user in "${users[@]}"; do
    log "Creating user: $user..."
    if id "$user" &> /dev/null; then
      log "$user already exists. Skipping..."
    else
      useradd -m -s /bin/bash "$user"
      mkdir -p "/home/$user/.ssh"
      touch "/home/$user/.ssh/authorized_keys"
      chown -R "$user:$user" "/home/$user/.ssh"

      # Add SSH keys
      cat <<EOF >> "/home/$user/.ssh/authorized_keys"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
# Add other user-specific keys here
EOF
    fi
  done

  # Grant sudo access to dennis
  log "Granting sudo access to dennis..."
  usermod -aG sudo dennis
}

# Function to install and configure software
function install_configure_software {
  ensure_package_installed openssh-server
  ensure_package_installed apache2
  ensure_package_installed squid

  log "Configuring OpenSSH..."
  sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
  systemctl restart ssh

  log "Configuring Apache..."
  systemctl enable apache2
  systemctl start apache2

  log "Configuring Squid Proxy..."
  systemctl enable squid
  systemctl start squid
}

# Main script execution
log "Starting script..."

configure_network
configure_firewall
create_users
install_configure_software

log "Script execution complete."
