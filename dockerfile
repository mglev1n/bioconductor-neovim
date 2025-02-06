ARG ARCH
ARG BASE_IMAGE

# hadolint ignore=DL3007
FROM ${ARCH}allaman/nvim-full:latest

USER root

# Install system dependencies and wget for mambaforge installation
RUN apt-get update && apt-get install -y \
    imagemagick \
    libmagickwand-dev \
    liblua5.1-0-dev \
    luajit \
    nodejs \
    npm \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Mambaforge
RUN wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" \
    && bash Miniforge3.sh -b -p "/opt/conda" \
    && rm Miniforge3.sh

# Add mamba to PATH
ENV PATH="/opt/conda/bin:$PATH"

# Initialize mamba
RUN mamba init bash

# Install R using mamba
RUN mamba install -y -c conda-forge \
    r-base=4.3.2 \
    r-devtools \
    r-essentials \
    && R --version

# Setup npm for non-root user and install tree-sitter-cli globally
RUN mkdir -p /home/nvim/.npm-global \
    && chown -R nvim:nvim /home/nvim/.npm-global \
    && npm config set prefix '/home/nvim/.npm-global' \
    && npm install -g tree-sitter-cli

# Switch back to nvim user for remaining operations
USER nvim

# Set up directory structure
RUN mkdir -p ~/.config/nvim \
    && mkdir -p ~/.local/share/nvim/mason/packages

# Clone quarto-nvim-kickstarter configuration
RUN git clone https://github.com/jmbuhr/quarto-nvim-kickstarter.git /tmp/quarto-config \
    && cp -r /tmp/quarto-config/* ~/.config/nvim/ \
    && rm -rf /tmp/quarto-config

# Create empty user config file
RUN echo "return {}" > ~/.nvim_config.lua

# Add mason tools and npm global dir to path
RUN echo "export PATH=$PATH:~/.local/share/nvim/mason/bin:/usr/bin/npm" >> ~/.bashrc \
    && echo "export PATH=$PATH:~/.local/share/nvim/mason/bin:/usr/bin/npm" >> ~/.profile \
    && mkdir -p ~/.npm-global \
    && npm config set prefix '~/.npm-global' \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.bashrc \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile

WORKDIR /home/nvim/.config/nvim

# Install plugins and tools
# Note: Increased sleep time to ensure proper installation of all plugins
RUN nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall" +sleep 60 +qa

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "nvim"]