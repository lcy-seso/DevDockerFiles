FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Create a non-root user with sudo privileges and install required packages
RUN useradd -m -s /bin/bash ying && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        zsh \
        curl \
        git \
        tmux \
        python3-pip \
        python3-setuptools && \
    echo "ying ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy tmux configuration file
COPY tmux.conf /etc/tmux.conf

# Create symbolic links to the global tmux configuration for both users
RUN ln -sf /etc/tmux.conf /root/.tmux.conf && \
    ln -sf /etc/tmux.conf /home/ying/.tmux.conf && \
    chown ying:ying /home/ying/.tmux.conf

# Set zsh as the default shell for all users
RUN echo "zsh" >> /etc/shells && \
    chsh -s /bin/zsh root && \
    chsh -s /bin/zsh ying && \
    # Add zsh to bashrc to ensure it starts even if bash is invoked
    echo "[ -t 1 ] && exec zsh" >> /root/.bashrc && \
    echo "[ -t 1 ] && exec zsh" >> /home/ying/.bashrc && \
    # Make sure the non-root user will also use zsh
    echo "[ -t 1 ] && exec zsh" >> /etc/skel/.bashrc

# Install Miniconda
RUN curl -sL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    chmod +x /tmp/miniconda.sh && \
    /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh && \
    # Set up conda environment
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate base" >> /root/.bashrc && \
    # Add conda to zsh configuration
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.zshrc && \
    echo "conda activate base" >> /root/.zshrc && \
    # Add conda to PATH
    export PATH="/opt/conda/bin:$PATH" && \
    # Update conda and pip
    /opt/conda/bin/conda update -y conda && \
    /opt/conda/bin/pip install --upgrade pip && \
    # Make conda accessible to all users
    chmod -R 777 /opt/conda

# Install pre-commit globally
RUN pip3 install --no-cache-dir pre-commit==3.6.0

# Install hadolint for Dockerfile linting
RUN curl -sL -o /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/download/v2.13.1-beta/hadolint-Linux-x86_64 && \
    chmod +x /usr/local/bin/hadolint

# Install other development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        shellcheck \
        yamllint && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure zsh to be the default shell for the container
SHELL ["/bin/zsh", "-c"]

# Set the working directory
WORKDIR /workspace

# Set environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Install oh-my-zsh for the ying user
USER ying
# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Configure zsh settings
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc && \
    echo 'plugins=(git docker)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc && \
    # Make sure conda is available in zsh
    echo 'export PATH="/opt/conda/bin:$PATH"' >> ~/.zshrc && \
    echo '. /opt/conda/etc/profile.d/conda.sh' >> ~/.zshrc && \
    echo 'conda activate base' >> ~/.zshrc

# Clean up to reduce image size
USER root
# Add conda to PATH for cleanup
ENV PATH="/opt/conda/bin:${PATH}"
# Switch to bash for cleanup commands
SHELL ["/bin/bash", "-c"]
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    conda clean -afy && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    # Remove apt caches
    find /var/cache/apt -type f -delete && \
    # Remove documentation files
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/* && \
    # Remove pip cache
    rm -rf /root/.cache/pip && \
    rm -rf /home/ying/.cache/pip

# Switch back to zsh for final operations
SHELL ["/bin/zsh", "-c"]
USER ying

# Set the default command to zsh
ENTRYPOINT ["zsh"]
