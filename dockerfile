FROM bioconductor/bioconductor:3.17

ARG BRANCH=stable

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        build-essential \
        ca-certificates \
        cmake \
        curl \
        fd-find \
        fzf \
        g++ \
        gettext \
        git \
        gnupg \
        libmagickwand-dev \
        liblua5.1-0-dev \
        luajit \
        make \
        ninja-build \
        python3-pip \
        ripgrep \
        sudo \
        tar \
        unzip \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$(which fdfind)" /usr/bin/fd \
    && ln -s "$(which python3)" /usr/bin/python

# Install Node.js 20
RUN apt-get remove -y libnode-dev \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# Install Rust and tree-sitter-cli
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && cargo install --locked tree-sitter-cli

# Build Neovim from source
RUN git clone -b ${BRANCH} https://github.com/neovim/neovim /tmp/neovim \
    && cd /tmp/neovim \
    && make CMAKE_BUILD_TYPE=RelWithDebInfo \
    && make install \
    && rm -fr /tmp/neovim

# Install Go
RUN curl -sLo go.tar.gz "https://go.dev/dl/go1.21.0.linux-amd64.tar.gz" \
    && tar -C /usr/local/bin -xzf go.tar.gz \
    && rm go.tar.gz

# Add user 'nvim' and allow passwordless sudo
RUN adduser --disabled-password --gecos '' nvim \
    && echo 'nvim ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set up environment variables
ENV PATH=$PATH:/usr/local/bin/go/bin/
ENV GOPATH=/home/nvim/.local/share/go
ENV PATH=$PATH:$GOPATH/bin

# Switch to nvim user for remaining operations
USER nvim
WORKDIR /home/nvim

# Set up directory structure and configs
RUN mkdir -p ~/.config/nvim \
    && mkdir -p ~/.local/share/nvim/mason/packages \
    && echo "return {}" > ~/.nvim_config.lua

# Set up npm for nvim user
RUN mkdir -p ~/.npm-global \
    && npm config set prefix '~/.npm-global' \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.bashrc \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile \
    && echo "export PATH=$HOME/.cargo/bin:$PATH" >> ~/.bashrc \
    && echo "export PATH=$HOME/.cargo/bin:$PATH" >> ~/.profile

# Clone and set up quarto-nvim-kickstarter
RUN git clone https://github.com/jmbuhr/quarto-nvim-kickstarter.git /tmp/quarto-config \
    && cp -r /tmp/quarto-config/* ~/.config/nvim/ \
    && rm -rf /tmp/quarto-config

# Install plugins and tools
RUN nvim --headless "+Lazy! sync" +qa \
    && nvim --headless "+MasonInstall" +sleep 60 +qa

# Add mason tools dir to path
RUN echo "export PATH=$PATH:~/.local/share/nvim/mason/bin" >> ~/.bashrc

ENTRYPOINT ["/bin/bash", "-c", "nvim"]