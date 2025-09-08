FROM ubuntu:22.04

# Install necessary dependencies
RUN apt-get update
RUN apt-get install -y python3-pip python3 git cmake pkg-config ninja-build build-essential \
libx11-dev libwxgtk3.0-gtk3-dev libfreetype6-dev pkg-config \
libfontconfig1-dev libass-dev libasound2-dev libffms2-dev intltool \
libboost-all-dev libhunspell-dev libuchardet-dev libpulse-dev \
libopenal-dev libxxhash-dev nasm liblua5.1-0-dev luarocks libcurl4-gnutls-dev


# Install Meson
RUN python3 -m pip install --upgrade pip setuptools
RUN pip3 install meson
RUN export PATH="$PATH:~/.local/bin"

# Build Arch1t3cht's Aegisub
WORKDIR /home

RUN git clone https://github.com/arch1t3cht/Aegisub.git -b feature_12
#RUN ls -la
WORKDIR /home/Aegisub
#RUN ls -la
RUN meson setup build --prefix=/usr --buildtype=release
RUN meson compile -C build
WORKDIR /home/Aegisub/build
RUN ninja install

RUN luarocks install luajson 1.3.3-1
RUN luarocks install moonscript


# Copy test input
WORKDIR /home

COPY ../input.ass .


# deps: FFMS2
RUN apt-get install -y ffmsindex
# deps: readline
RUN apt-get install libreadline8 libreadline-dev
# deps: wxWidgets - https://gist.github.com/pemd-sys/6aed397bcbdb380cb53bc09183f3a8f4
RUN apt-get install -y libgtk2.0-dev
RUN apt-get install -y libgtk-3-dev
RUN apt-get install -y mesa-utils
RUN apt-get install -y freeglut3-dev
RUN apt-get install -y libjpeg-dev
RUN apt-get install -y liblzma-dev

RUN apt-get update && apt-get install -y \
    libwxgtk3.0-gtk3-0v5 libwxbase3.0-0v5 libwxgtk3.0-gtk3-0v5 \
    && rm -rf /var/lib/apt/lists/*

# Test gui dependancys
# deps: installing wxWidgets
WORKDIR /usr/bin
RUN curl -LJO https://github.com/wxWidgets/wxWidgets/releases/download/v3.0.5/wxWidgets-3.0.5.tar.bz2
RUN tar -xvf wxWidgets-3.0.5.tar.bz2
WORKDIR /usr/bin/wxWidgets-3.0.5
RUN mkdir gtk-build
WORKDIR /usr/bin/wxWidgets-3.0.5/gtk-build
RUN ../configure --with-gtk=3 --with-opengl
RUN apt-get install -y libreadline8 libreadline-dev
RUN make -j3
RUN make install
RUN ldconfig


# Install Aegisub-cli
WORKDIR /home
RUN git clone https://github.com/Myaamori/aegisub-cli

WORKDIR /home/aegisub-cli/libaegisub/common
RUN rm /home/aegisub-cli/libaegisub/common/fs.cpp
COPY ./src/fs.cpp .


WORKDIR /home/aegisub-cli
RUN python3 -m pip install meson==0.62 # Downgrade Meson due to sandbox violation (known issue)

RUN meson --prefix=/usr --buildtype=release build
RUN meson compile -C build src/aegisub-cli

RUN mv build/src/aegisub-cli /usr/bin/
RUN mv build/src/libresrc/libresrc.a /usr/lib/
RUN mv build/src/libresrc/default_config.h /usr/include/


WORKDIR /home


#USER aegisub

ARG HOME='/root'

# Set up `Automation 4` modules for Aegisub
RUN mkdir -p ${HOME}/.aegisub/automation

# custom scripts
WORKDIR /home/.aegisub/automation/autoload
COPY ../scripts .

WORKDIR ${HOME}/.aegisub/automation

# Download Depndency Control
RUN apt install tar
RUN curl -L https://github.com/RellikJaeger/DependencyControl/releases/download/v0.6.4-alpha/DependencyControl-v0.6.4-Linux-amd64.tar.gz -o DependencyControl-v0.6.4-Linux-amd64.tar.gz
RUN tar -xvf ./DependencyControl-v0.6.4-Linux-amd64.tar.gz

WORKDIR ${HOME}/.aegisub/automation/DependencyControl-v0.6.4-Linux-amd64

# Fix problem with Logger
WORKDIR ${HOME}/.aegisub/automation/DependencyControl-v0.6.4-Linux-amd64/include/l0/DependencyControl

RUN rm ./Logger.moon
COPY ../src/Logger.moon .

RUN mv ${HOME}/.aegisub/automation/DependencyControl-v0.6.4-Linux-amd64/* ${HOME}/.aegisub/automation



WORKDIR ${HOME}/.aegisub/automation

# build Subinspector
RUN git clone https://github.com/TypesettingTools/SubInspector.git
WORKDIR ${HOME}/.aegisub/automation/SubInspector
RUN meson build
WORKDIR ${HOME}/.aegisub/automation/SubInspector/build
RUN ninja
RUN mkdir -p ${HOME}/.aegisub/automation/include/SubInspector
RUN mkdir -p ${HOME}/.aegisub/automation/include/SubInspector/Inspector

RUN apt-get update && apt-get install -y xvfb



# SubInspector
RUN mv ${HOME}/.aegisub/automation/SubInspector/examples/Aegisub/Inspector.moon ${HOME}/.aegisub/automation/include/SubInspector
RUN mv ${HOME}/.aegisub/automation/SubInspector/build/src/libSubInspector.so ${HOME}/.aegisub/automation/include/SubInspector/Inspector

# add right feed to installation
RUN mkdir -p ${HOME}/.aegisub/config/
COPY ./src/l0.DependencyControl.json ${HOME}/.aegisub/config/
#RUN curl -L https://raw.githubusercontent.com/RellikJaeger/DependencyControl/refs/tags/v0.6.4-alpha/DependencyControl.json -o l0.DependencyControl.json

# Fix issue with yutils not getting installed
RUN curl -L https://raw.githubusercontent.com/TypesettingTools/Yutils/refs/heads/master/src/Yutils.lua -o /usr/local/share/lua/5.1/Yutils.lua

# Install missings Fonts
RUN apt-get update && apt-get install -y \
    fonts-liberation \
    fonts-dejavu \
    fontconfig \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


RUN mkdir -p ${HOME}/.aegisub/log

WORKDIR /home

RUN Xvfb :99 -screen 0 1024x768x16 &
RUN export DISPLAY=:99

RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script"
RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button": 0, "values": {"macro":"Shapery v2.6.1"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script"

#aegisub-cli --automation ILL.Shapery.moon --loglevel 4 input.ass dummy_out.ass ": Shapery macros :/Shape expand"