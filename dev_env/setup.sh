#!/bin/bash

rm -f /tmp/miniconda.sh

ln -sf /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh
echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
echo "conda activate base" >> ~/.bashrc
export PATH="/opt/conda/bin:$PATH"
conda update -y conda
pip install --upgrade pip

pip3 install --no-cache-dir pre-commit==4.2.0

curl -sL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.13.1-beta/hadolint-Linux-x86_64
chmod +x /usr/local/bin/hadolint

sudo apt-get install -y --no-install-recommends \
    shellcheck \
    yamllint

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

echo "export ZSH=\"$HOME/.oh-my-zsh\"" >> ~/.zshrc
echo "ZSH_THEME=\"robbyrussell\"" >> ~/.zshrc
echo "plugins=(git docker)" >> ~/.zshrc
echo "source $ZSH/oh-my-zsh.sh" >> ~/.zshrc
echo "export PATH=\"/opt/conda/bin:$PATH\"" >> ~/.zshrc
echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.zshrc
echo "conda activate base" >> ~/.zshrc

sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
conda clean -afy
sudo rm -rf /tmp/* /var/tmp/*
sudo find /var/cache/apt -type f -delete
sudo rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*
sudo rm -rf ~/.cache/pip

echo "Setup complete. Please restart your shell or source ~/.bashrc to apply changes."
