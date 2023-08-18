# Download base image
FROM ubuntu:22.04

# Add apt china source
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak \
    && sed -i 's@//.*archive.ubuntu.com@//mirrors.ustc.edu.cn@g' /etc/apt/sources.list

# Setting timezone
ENV TZ=US/Alaska
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Upgrade system
RUN apt update \
    && apt upgrade -y

# Install pre-packet
RUN apt install git build-essential openssl wget ninja-build gettext pkg-config libtool automake cmake unzip curl -y

# Install other tools
RUN apt install python3-neovim -y

# Get neovim config
RUN mkdir -p ~/.config \
    && git clone https://github.com/xiaolitongxue666/nvim.git ~/.config/nvim

# Build neovim
RUN cd ~ \
    && wget https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz \
    && tar -zxvf nvim-linux64.tar.gz  \
    && cd /usr/bin \
    && rm -rf /usr/bin/nvim \
    && ln -sf ~/nvim-linux64/bin/nvim nvim


