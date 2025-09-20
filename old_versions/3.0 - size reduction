FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install all dependencies needed for build + runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools git curl ca-certificates \
    cmake pkg-config ninja-build build-essential \
    libx11-dev libwxgtk3.0-gtk3-dev libfreetype6-dev libfontconfig1-dev \
    libass-dev libasound2-dev libffms2-dev intltool \
    libhunspell-dev libuchardet-dev libpulse-dev \
    libopenal-dev libxxhash-dev nasm lua5.1 liblua5.1-0-dev luarocks \
    libcurl4-gnutls-dev libreadline8 libreadline-dev \
    libgtk2.0-dev libgtk-3-dev freeglut3-dev libjpeg-dev \
    liblzma-dev \
    libboost-all-dev \
    libboost-filesystem1.74.0 libboost-locale1.74.0 libboost-regex1.74.0 libboost-thread-dev \
    libffms2-5 libboost-program-options1.74.0 libboost-filesystem1.74.0 libboost-system1.74.0 libboost-chrono1.74.0 \
    fonts-liberation fonts-dejavu fontconfig xvfb \
    && python3 -m pip install --upgrade pip meson \
    && rm -rf /var/lib/apt/lists/*

# mesa-utils
# libboost-filesystem1.74.0 libboost-locale1.74.0 libboost-regex1.74.0 libboost-thread-dev \
# libffms2-5 libboost-program-options1.74.0 libboost-filesystem1.74.0 libboost-system1.74.0 libboost-chrono1.74.0 \

# ---- Build wxWidgets ----
WORKDIR /build/wx
RUN curl -LJO https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2 \
    && tar -xf wxWidgets-3.0.5.tar.bz2 \
    && cd wxWidgets-3.0.5 \
    && mkdir gtk-build \
    && cd gtk-build \
    && ../configure --with-gtk=3 --with-opengl --disable-debug --enable-optimise \
    && make -j$(nproc) \
    && make install \
    && ldconfig \
    && cd /build && rm -rf wx

# ---- Lua dependencies ----
RUN luarocks --lua-version=5.1 install luajson 1.3.3-1 \
 && luarocks --lua-version=5.1 install moonscript \
 && luarocks --lua-version=5.1 install luafilesystem

# ---- Build Aegisub ----
WORKDIR /build
RUN apt-get update && apt-get install -y --no-install-recommends mesa-utils libboost-all-dev
RUN git clone https://github.com/arch1t3cht/Aegisub.git -b feature_12 \
    && cd Aegisub \
    && meson setup build --prefix=/usr --buildtype=release \
    && meson compile -C build \
    && cd build \
    && ninja install


# ---- Build aegisub-cli ----
RUN python3 -m pip install meson==0.62 # Downgrade Meson due to sandbox violation (known issue)
WORKDIR /build
COPY ./src/fs.cpp /tmp/fs.cpp
RUN git clone https://github.com/Myaamori/aegisub-cli \
    && cd ./aegisub-cli \
    && rm libaegisub/common/fs.cpp \
    && mv /tmp/fs.cpp libaegisub/common/ \
    && meson --prefix=/usr --buildtype=release build  \
    && meson compile -C build src/aegisub-cli \
    && mv build/src/aegisub-cli /usr/local/bin/ \
    && mv build/src/libresrc/libresrc.a /usr/local/lib/ \
    && mv build/src/libresrc/default_config.h /usr/local/include/


# ---- Setup Aegisub automation ----
ARG HOME='/root'
RUN mkdir -p ${HOME}/.aegisub/config/ \
    && mkdir -p ${HOME}/.aegisub/log \
    && mkdir -p ${HOME}/.aegisub/automation/autoload \
    && mkdir -p ${HOME}/.aegisub/automation/include

# ---- Build Dependency Control ----
WORKDIR /build
COPY ../src/Logger.moon ./Logger.moon
RUN curl -L https://github.com/RellikJaeger/DependencyControl/releases/download/v0.6.4-alpha/DependencyControl-v0.6.4-Linux-amd64.tar.gz \
    | tar -xz \
    && rm -f DependencyControl-v0.6.4-Linux-amd64/include/l0/DependencyControl/Logger.moon \
    && cp Logger.moon DependencyControl-v0.6.4-Linux-amd64/include/l0/DependencyControl/ \
    && mv ./DependencyControl-v0.6.4-Linux-amd64/include/* ${HOME}/.aegisub/automation/include/ \
    && mv ./DependencyControl-v0.6.4-Linux-amd64/autoload/* ${HOME}/.aegisub/automation/autoload/

# ---- Cleanup build deps to shrink image ----
RUN apt-get purge -y --auto-remove \
    cmake pkg-config ninja-build build-essential \
    libx11-dev libwxgtk3.0-gtk3-dev libfreetype6-dev libfontconfig1-dev \
    libass-dev libasound2-dev libffms2-dev intltool \
    libboost-all-dev libhunspell-dev libuchardet-dev libpulse-dev \
    libopenal-dev libxxhash-dev nasm liblua5.1-0-dev \
    libcurl4-gnutls-dev libreadline-dev libgtk2.0-dev \
    freeglut3-dev libjpeg-dev liblzma-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /build/*

# ---- Automation scripts ----
WORKDIR ${HOME}/.aegisub/automation
COPY ../scripts ./scripts/
#COPY ./src/l0.DependencyControl.json ./l0.DependencyControl.json


WORKDIR /home
COPY ../input.ass .


# Test run
RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script" || true
RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button": 0, "values": {"macro":"Shapery v2.6.1"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script" || true
#RUN aegisub-cli --automation ILL.Shapery.moon --loglevel 4 input.ass dummy_out.ass ": Shapery macros :/Shape expand" || true
