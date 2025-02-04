FROM bioconductor/tidyverse:3.17

USER root

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    npm \
    python3-pip \
    && add-apt-repository -y ppa:neovim-ppa/unstable \
    && apt-get update && \
    apt-get install -y --no-install-recommends \
    neovim \
    lua5.1 \
    liblua5.1-dev \
    luarocks \
    && rm -rf /var/lib/apt/lists/*

# Install LuaRocks packages needed for Neovim extensions
RUN luarocks install lpeg \
    && luarocks install luautf8 \
    && luarocks install inspect

# Switch to rstudio user for configuration
USER rstudio
WORKDIR /home/rstudio

# Install Python packages for Neovim
RUN pip3 install --user pynvim

# Create Neovim config directory and clone kickstarter
RUN mkdir -p .config/nvim \
    && git clone https://github.com/jmbuhr/quarto-nvim-kickstarter.git .config/nvim

# Install Neovim plugins and language servers
RUN nvim --headless -c "Lazy! sync" -c "qa" \
    && nvim --headless -c "MasonInstall quarto-lsp r-languageserver bash-language-server" -c "qa"

# Install Tree-sitter parsers for better syntax highlighting
RUN nvim --headless -c "TSInstall r python bash javascript" -c "qa"

USER root

# Verify installations
RUN nvim --version \
    && luarocks --version \
    && pip3 show pynvim \
    && npm --version