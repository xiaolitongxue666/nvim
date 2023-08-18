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
RUN apt install git sudo build-essential openssl wget ninja-build gettext pkg-config libtool automake cmake unzip curl -y

# Install other tools
RUN apt install python3-neovim -y

# Build neovim
RUN cd ~ \
    && wget https://github.com/neovim/neovim/releases/download/v0.9.1/nvim-linux64.tar.gz \
    && tar -zxvf nvim-linux64.tar.gz  \
    && cd /usr/bin \
    && rm -rf /usr/bin/nvim \
    && ln -sf ~/nvim-linux64/bin/nvim nvim

# Complete neovim enviroment
RUN curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -

# Install node 14 and npm
RUN dpkg --remove --force-remove-reinstreq libnode-dev \
    && dpkg --remove --force-remove-reinstreq libnode72:amd64 \
    && apt update \
    && apt install nodejs -y

RUN apt install ruby-full golang-go -y \
    && gem install neovim

#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | bash -s -- -y \
#    && echo 'source $HOME/.cargo/env' >> $HOME/.bashrc \
#    && source $HOME/.bashrc \
#    && cargo install tree-sitter-cli \
#    && cargo install stylua \
#    && apt install luarocks default-jre default-jdk python3-pip black -y
#
#RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.2-linux-x86_64.tar.gz \
#    && tar -zxvf julia-1.9.2-linux-x86_64.tar.gz \
#    && rm -rf /usr/bin/julia \
#    && cd /usr/bin \
#    && ln -sf ~/julia-1.9.2/bin/julia julia
#
#RUN cd ~ \
#    && curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php \
#    && chmod 777 /tmp/composer-setup.php \
#    && HASH=`curl -sS https://composer.github.io/installer.sig` \
#    && echo $HASH \
#    && php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
#    && sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
#
#RUN pip3 install --upgrade pynvim \
#    && npm install -g neovim
#
## Get neovim config
#RUN mkdir -p ~/.config \
#    && git clone https://github.com/xiaolitongxue666/nvim.git ~/.config/nvim
