# Stage 1: Builder stage
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS builder

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    vim \
    zsh \
    curl \
    git \
    tmux \
    build-essential \
    openjdk-8-jdk \
    openssh-server \
    openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Miniconda
RUN curl -sL https://repo.anaconda.com/archive/Anaconda3-2024.10-1-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    chmod +x /tmp/miniconda.sh && \
    /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

# Set up conda environment
ENV PATH="/opt/conda/bin:${PATH}"
RUN conda update -y conda && \
    pip install --upgrade --no-cache-dir pip==25.0.1

# Set up Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Install zsh-autosuggestions plugin
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" && \
    # Install zsh-syntax-highlighting plugin
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" && \
    # Configure zsh plugins
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Configure zsh with aliases and conda initialization
RUN printf "\\nalias cls='clear'\\n" >> ~/.zshrc && \
    echo "alias ll='ls -l'" >> ~/.zshrc && \
    echo "alias la='ls -a'" >> ~/.zshrc && \
    echo "alias vi='vim'" >> ~/.zshrc && \
    echo "alias grep='grep --color=auto'" >> ~/.zshrc && \
    echo "alias -s py=vi" >> ~/.zshrc && \
    # Ensure conda is properly activated in zsh
    echo "export PATH=\"/opt/conda/bin:\$PATH\"" >> ~/.zshrc && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.zshrc && \
    echo "conda activate base" >> ~/.zshrc

# Set up conda initialization
RUN conda init bash && \
    conda init zsh

# Set shell to bash for conda operations
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Update Python in base environment
RUN echo "Installing Python 3.12 in the base environment..." && \
    conda install -y -n base python=3.12 && \
    conda install -y -n base pip

# Return to the default shell for subsequent RUN commands
SHELL ["/bin/sh", "-c"]

# Copy requirements.txt to the container
COPY requirements.txt /tmp/requirements.txt

# Set shell to bash for pip operations that require the conda environment
SHELL ["/bin/bash", "--login", "-o", "pipefail", "-c"]

# Install Python packages from requirements.txt
RUN echo "Installing Python packages from requirements.txt..." && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt && \
    # Install pre-commit globally
    pip install --no-cache-dir pre-commit==4.2.0

# Return to the default shell
SHELL ["/bin/sh", "-c"]

# Install hadolint for Dockerfile linting
RUN curl -sL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.13.1-beta/hadolint-Linux-x86_64 && \
    chmod +x /usr/local/bin/hadolint

# Clean up to reduce image size
RUN conda clean -afy && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/* && \
    find /var/cache/apt -type f -delete && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*

# Second stage: create the final image
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Set shell with pipefail option to address DL4006 warning
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy conda and other necessary files from builder
COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/hadolint
COPY --from=builder /root/.oh-my-zsh /root/.oh-my-zsh
COPY --from=builder /root/.zshrc /root/.zshrc

# Install minimal required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    zsh \
    curl \
    git \
    tmux \
    vim && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY tmux.conf /etc/tmux.conf
COPY vimrc /etc/vim/vimrc.local

# Set up Vim configuration
RUN mkdir -p /root/.vim/autoload /root/.vim/colors && \
    # Install vim-plug for plugin management
    curl -fLo /root/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    # Install gruvbox color scheme
    curl -fLo /root/.vim/colors/gruvbox.vim --create-dirs \
    https://raw.githubusercontent.com/morhetz/gruvbox/master/colors/gruvbox.vim && \
    # Create symlink to global vimrc
    ln -sf /etc/vim/vimrc.local /root/.vimrc

# Create symbolic link to the global tmux configuration for root user
RUN ln -sf /etc/tmux.conf /root/.tmux.conf

# Set zsh as the default shell for root user
RUN echo "zsh" >> /etc/shells && \
    chsh -s /bin/zsh root && \
    # Add zsh to bashrc to ensure it starts even if bash is invoked
    echo "[ -t 1 ] && exec zsh" >> /root/.bashrc && \
    # Install zsh plugins directly in final image with explicit paths
    git clone https://github.com/zsh-users/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Configure zsh to be the default shell for the container
SHELL ["/bin/zsh", "-o", "pipefail", "-c"]

# Set the working directory
WORKDIR /workspace

# Set environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:/opt/conda/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Configure Git to trust the workspace directory by default
RUN git config --system --add safe.directory '*' && \
    git config --global user.name "lcy-seso" && \
    git config --global user.email "lcy.seso@gmail.com" && \
    # Set up SSH server
    mkdir -p /var/run/sshd && \
    # Disable strict host key checking for localhost connections
    mkdir -p /root/.ssh && \
    echo "Host localhost\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null" > /root/.ssh/config && \
    # Set SSH configuration to allow password authentication
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    # Set a secure password for root
    echo "root:Docker!" | chpasswd

# Add a script to start services and then execute the provided command or default shell
COPY <<-"EOF" /usr/local/bin/entrypoint.sh
#!/bin/bash

# Start SSH server in the background
echo "Starting SSH server..."
/usr/sbin/sshd

# Check if we're running as root
if [ "$(id -u)" -eq 0 ]; then
    # Make sure the gruvbox theme is available for root
    mkdir -p /root/.vim/colors

    if [ ! -f "/root/.vim/colors/gruvbox.vim" ]; then
        curl -fLo /root/.vim/colors/gruvbox.vim --create-dirs \
        https://raw.githubusercontent.com/morhetz/gruvbox/master/colors/gruvbox.vim
    fi
else
    # We're running as non-root user, set up vim colors for current user
    mkdir -p ~/.vim/colors

    if [ ! -f "$HOME/.vim/colors/gruvbox.vim" ]; then
        curl -fLo "$HOME/.vim/colors/gruvbox.vim" --create-dirs \
        https://raw.githubusercontent.com/morhetz/gruvbox/master/colors/gruvbox.vim
    fi
fi

# Fix for Git "dubious ownership" errors with mounted volumes
if [ -d "/workspace" ]; then
    echo "Setting Git to trust repositories in /workspace..."
    # Use --global instead of --system to avoid permission issues
    git config --global --add safe.directory '*'
    git config --global --add safe.directory /workspace
    
    # Find other Git repositories in workspace and trust them
    find /workspace -maxdepth 3 -name ".git" -type d | while read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        echo "Trusting Git repository: $repo_dir"
        git config --global --add safe.directory "$repo_dir"
    done
fi

# Execute the command passed to docker run, or zsh if none
if [ $# -eq 0 ]; then
    exec /bin/zsh
else
    exec "$@"
fi
EOF

# Make the entrypoint script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Note: We're intentionally keeping root as the user despite DL3002 warning
# since this is a development container in a controlled environment

# Expose SSH port
EXPOSE 22

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
