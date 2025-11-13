if dpkg -l | grep ghostty; then
  echo "Ghostty is already installed"
  exit 0
fi

# 1. Download and store the repository signing key (dearmored)
if [ ! -f /usr/share/keyrings/debian.griffo.io.gpg ]; then
sudo curl -fsSL https://debian.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/debian.griffo.io.gpg
fi

# 2. Add the repository, referencing the keyring using 'signed-by'
if [ ! -f /etc/apt/sources.list.d/debian.griffo.io.list ]; then
echo "deb [signed-by=/usr/share/keyrings/debian.griffo.io.gpg] \
  https://debian.griffo.io/apt $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/debian.griffo.io.list
fi

# 3. Update and install
sudo apt update
sudo apt install -y ghostty
