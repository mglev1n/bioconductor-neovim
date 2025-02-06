ARG ARCH
ARG BASE_IMAGE

# hadolint ignore=DL3007
FROM ${ARCH}allaman/nvim-full:latest

USER root

# Install system dependencies required for image.nvim and quarto
RUN apt-get update && apt-get install -y \
    imagemagick \
    libmagickwand-dev \
    liblua5.1-0-dev \
    luajit \
    tree-sitter-cli \
    && rm -rf /var/lib/apt/lists/*

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

# Add mason tools dir to path
RUN echo "PATH=$PATH:~/.local/share/nvim/mason/bin" >> ~/.bashrc

WORKDIR /home/nvim/.config/nvim

# Install plugins and tools
# Note: Increased sleep time to ensure proper installation of all plugins
RUN nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall" +sleep 60 +qa

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "nvim"]