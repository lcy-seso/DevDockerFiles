#!/bin/bash

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running with sudo privileges
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root (use sudo)"
        exit 1
    fi
}

# Update package lists
echo "Updating package lists..."
sudo apt-get update

# Install essential build tools
echo "Installing essential build tools..."
sudo apt-get install -y build-essential curl wget git

# Install zsh if not already installed
if ! command_exists zsh; then
    echo "Installing zsh..."
    sudo apt-get install -y zsh
else
    echo "zsh is already installed"
fi

# Install oh-my-zsh if not already installed
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "oh-my-zsh is already installed"
fi

# Set zsh as default shell for current user
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Setting zsh as default shell (user-level)..."
    # Add zsh shell startup to .profile if not already present
    if ! grep -q "exec zsh" ~/.profile; then
        echo '# Start zsh if it exists and we are in an interactive shell' >>~/.profile
        echo 'if [ -x "$(command -v zsh)" ] && [ -n "$PS1" ]; then' >>~/.profile
        echo '    exec zsh' >>~/.profile
        echo 'fi' >>~/.profile
    fi
else
    echo "zsh is already the default shell"
fi

# Install Miniconda if not already installed
if [ ! -d "$HOME/miniconda" ]; then
    echo "Installing Miniconda..."
    wget https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p $HOME/miniconda
    rm ~/miniconda.sh
else
    echo "Miniconda is already installed"
fi

# Set up conda environment
echo "Setting up conda environment..."
# Add conda to PATH
export PATH="$HOME/miniconda/bin:${PATH}"

# Configure conda initialization and automatic base activation for bash
if ! grep -q "conda.sh" ~/.bashrc; then
    cat >>~/.bashrc <<'EOL'
# Initialize Conda
if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda/etc/profile.d/conda.sh"
    conda activate base
fi
EOL
fi

# Configure conda initialization and automatic base activation for zsh
if ! grep -q "conda.sh" ~/.zshrc; then
    cat >>~/.zshrc <<'EOL'
# Initialize Conda
if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
    . "$HOME/miniconda/etc/profile.d/conda.sh"
    conda activate base
fi
EOL
fi

# Initialize conda for the current shell
echo "Initializing conda for the current shell..."
source $HOME/miniconda/etc/profile.d/conda.sh
conda activate base

# Update conda
echo "Updating conda..."
conda update -n base -c defaults conda -y

# Install pip3 in the conda environment
conda install -n base pip -y

# Install Python packages for Vim and development
echo "Installing Python packages..."
pip3 install --upgrade pip

# Install packages from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
    echo "Installing packages from requirements.txt..."
    pip3 install -r requirements.txt
else
    # Install minimal set of Python packages if requirements.txt doesn't exist
    echo "requirements.txt not found, installing minimal set of packages..."
    pip3 install black isort flake8 pylint
fi

# Install Node.js for COC.nvim
if ! command_exists node; then
    echo "Installing Node.js for COC.nvim..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi

# Configure npm to use user directory
echo "Configuring npm to use user directory..."
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'

# Add npm-global to PATH if not already added
if ! grep -q "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" ~/.zshrc; then
    echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >>~/.zshrc
fi

# Install global npm packages for Vim
echo "Installing npm packages for Vim..."
export PATH=~/.npm-global/bin:$PATH
npm install -g typescript @types/node

# Install Vim plugins
echo "Installing Vim plugins..."
# Create a temporary vimrc for plugin installation
cat >~/.vimrc.tmp <<'EOL'
call plug#begin('~/.vim/plugged')
Plug 'junegunn/vim-plug'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim'
Plug 'dense-analysis/ale'
Plug 'Yggdroot/indentLine'
Plug 'airblade/vim-gitgutter'
Plug 'mhinz/vim-startify'
Plug 'morhetz/gruvbox'
Plug 'JuliaEditorSupport/julia-vim'
Plug 'mindriot101/vim-yapf'
Plug 'wuye/wuye.vim'  " Wuye colorscheme
call plug#end()
EOL

# Install plugins using the temporary vimrc
vim -u ~/.vimrc.tmp +PlugInstall +qall

# Clean up temporary vimrc
rm ~/.vimrc.tmp

# Build COC.nvim
echo "Building COC.nvim..."
if [ -d ~/.vim/plugged/coc.nvim ]; then
    cd ~/.vim/plugged/coc.nvim
    npm ci
    npm run build
    cd -
else
    echo "Warning: COC.nvim directory not found. Please run :PlugInstall in Vim first."
fi

# Install development tools
echo "Installing development tools..."
sudo apt-get install -y \
    universal-ctags \
    vim \
    tmux \
    ripgrep \
    fd-find \
    tree \
    htop

# Install Hadolint (Dockerfile linter) in user directory
echo "Installing Hadolint..."
mkdir -p $HOME/.local/bin
HADOLINT_VERSION=$(curl -s "https://api.github.com/repos/hadolint/hadolint/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
wget -O $HOME/.local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-x86_64"
chmod +x $HOME/.local/bin/hadolint

# Add .local/bin to PATH if not already added
if ! grep -q "export PATH=\"\$HOME/.local/bin:\$PATH\"" ~/.zshrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >>~/.zshrc
fi

# Add common aliases if not already present
echo "Configuring shell aliases..."
declare -A aliases
aliases=(
    ["cls"]="clear"
    ["ll"]="ls -l"
    ["la"]="ls -a"
    ["vi"]="vim"
    ["grep"]="grep --color=auto"
)

# Add regular aliases
for alias_name in "${!aliases[@]}"; do
    if ! grep -q "alias $alias_name=" ~/.zshrc; then
        echo "alias $alias_name='${aliases[$alias_name]}'" >>~/.zshrc
    fi
done

# Add suffix alias for Python files
if ! grep -q "alias -s py=vi" ~/.zshrc; then
    echo "alias -s py=vi" >>~/.zshrc
fi

# Set vim as default git editor
echo "Setting vim as default git editor..."
git config --global core.editor "vim"

# Copy and source tmux configuration if it exists
if [ -f "tmux.conf" ]; then
    echo "Copying tmux configuration to home directory..."
    cp tmux.conf $HOME/.tmux.conf
    echo "Sourcing tmux configuration..."
    tmux source-file $HOME/.tmux.conf
else
    echo "No tmux configuration found, skipping..."
fi

# Set up Vim configuration
echo "Setting up Vim configuration..."
# Create necessary directories
mkdir -p ~/.vim/autoload
mkdir -p ~/.vim/plugged

# Install Vim-Plug
if [ ! -f ~/.vim/autoload/plug.vim ]; then
    echo "Installing Vim-Plug..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# Copy vimrc
echo "Copying vimrc..."
cp $(dirname "$0")/vimrc ~/.vimrc

# Install fzf for fuzzy finding
if [ ! -d ~/.fzf ]; then
    echo "Installing fzf..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

echo "Setup completed successfully!"
echo "Please restart your terminal to apply all changes."
