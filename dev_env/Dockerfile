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
        python3-pip \
        python3-setuptools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Miniconda
RUN curl -sL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh && \
    chmod +x /tmp/miniconda.sh && \
    /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

# Set up conda environment
ENV PATH="/opt/conda/bin:${PATH}"
RUN conda update -y conda && \
    pip install --upgrade --no-cache-dir pip==25.0.1

# Copy requirements.txt to the container
COPY requirements.txt /tmp/requirements.txt

# Install Python packages from requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Install pre-commit globally
RUN pip install --no-cache-dir pre-commit==4.2.0

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

# Clean up to reduce image size
RUN conda clean -afy && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/* && \
    find /var/cache/apt -type f -delete && \
    rm -rf /usr/share/doc/* /usr/share/man/* /usr/share/info/*

# Second stage: create the final image
FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04

# Copy conda and other necessary files from builder
COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /usr/local/bin/hadolint /usr/local/bin/hadolint

# Install minimal required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        sudo \
        zsh \
        curl \
        git \
        tmux \
        vim \
        shellcheck \
        yamllint && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy tmux configuration file
COPY tmux.conf /etc/tmux.conf

# Create symbolic link to the global tmux configuration for root user
RUN ln -sf /etc/tmux.conf /root/.tmux.conf

# Set zsh as the default shell for root user
RUN echo "zsh" >> /etc/shells && \
    chsh -s /bin/zsh root && \
    # Add zsh to bashrc to ensure it starts even if bash is invoked
    echo "[ -t 1 ] && exec zsh" >> /root/.bashrc

# Set up conda environment
ENV PATH="/opt/conda/bin:${PATH}"
RUN ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.bashrc && \
    echo "conda activate base" >> /root/.bashrc && \
    # Add conda to zsh configuration
    echo ". /opt/conda/etc/profile.d/conda.sh" >> /root/.zshrc && \
    echo "conda activate base" >> /root/.zshrc

# Configure zsh to be the default shell for the container
SHELL ["/bin/zsh", "-c"]

# Set the working directory
WORKDIR /workspace

# Set environment variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# Install oh-my-zsh for root user
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended && \
    # Configure zsh settings
    echo 'export ZSH="$HOME/.oh-my-zsh"' >> ~/.zshrc && \
    echo 'ZSH_THEME="robbyrussell"' >> ~/.zshrc && \
    echo 'plugins=(git docker)' >> ~/.zshrc && \
    echo 'source $ZSH/oh-my-zsh.sh' >> ~/.zshrc && \
    # Make sure conda is available in zsh
    echo '\nexport PATH="/opt/conda/bin:$PATH"' >> ~/.zshrc && \
    echo '. /opt/conda/etc/profile.d/conda.sh' >> ~/.zshrc && \
    echo 'conda activate base' >> ~/.zshrc

RUN echo "\nalias cls='clear'" >> ~/.zshrc && \
    echo "alias ll='ls -l'" >> ~/.zshrc && \
    echo "alias la='ls -a'" >> ~/.zshrc && \
    echo "alias vi='vim'" >> ~/.zshrc && \
    echo "alias grep='grep --color=auto'" >> ~/.zshrc && \
    echo "alias -s py=vi" >> ~/.zshrc

# Set the default command to zsh
ENTRYPOINT ["zsh"]
