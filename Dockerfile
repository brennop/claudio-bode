FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    luajit \
    libluajit-5.1-dev \
    luarocks \
    libssl-dev \
    pkg-config \
    libreadline-dev

RUN luarocks install fennel
RUN luarocks install readline
RUN luarocks install lua-openai

WORKDIR /workspace
