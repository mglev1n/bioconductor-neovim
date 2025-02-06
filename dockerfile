FROM bioconductor/bioconductor:3.17

ARG BRANCH=stable

# Install neovim build dependencies and other required packages
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
        nodejs \
        npm \
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

# Set up npm for nvim user and install tree-sitter-cli
RUN mkdir -p ~/.npm-global \
    && npm config set prefix '~/.npm-global' \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.bashrc \
    && echo "export PATH=~/.npm-global/bin:$PATH" >> ~/.profile \
    && . ~/.profile \
    && npm install -g tree-sitter-cli

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