ARG ARCH
ARG BASE_IMAGE

# hadolint ignore=DL3007
FROM ${ARCH}allaman/nvim-full:latest

USER root

# Install system dependencies required for image.nvim, quarto, and R
RUN apt-get update && apt-get install -y \
    imagemagick \
    libmagickwand-dev \
    liblua5.1-0-dev \
    luajit \
    nodejs \
    npm \
    # R dependencies
    dirmngr \
    gnupg \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Add R 4.3 repository
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc \
    && add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/" \
    && apt-get update

# Install R 4.3.2 and common R packages
RUN apt-get install -y \
    r-base=4.3* \
    r-base-dev=4.3* \
    # Additional R system dependencies
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

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