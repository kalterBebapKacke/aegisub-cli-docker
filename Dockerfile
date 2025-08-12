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

# Set up `Automation 4` modules for Aegisub
RUN mkdir -p /home/.aegisub/automation
WORKDIR /home/.aegisub/automation

RUN git clone https://github.com/TypesettingTools/DependencyControl.git
RUN git clone https://github.com/TypesettingTools/YUtils.git
RUN git clone https://github.com/arch1t3cht/ffi-experiments.git
RUN git clone https://github.com/TypesettingTools/ILL-Aegisub-Scripts.git
RUN git clone https://github.com/TypesettingTools/SubInspector.git

# build Subinspector
WORKDIR /home/.aegisub/automation/SubInspector
RUN meson build
WORKDIR /home/.aegisub/automation/SubInspector/build
RUN ninja
RUN mkdir -p /home/.aegisub/automation/include/SubInspector
RUN mkdir -p /home/.aegisub/automation/include/SubInspector/Inspector


WORKDIR /home/.aegisub/automation/DependencyControl
RUN git checkout v0.6.3-alpha

# Fix problem with Logger
WORKDIR /home/.aegisub/automation/DependencyControl/modules/DependencyControl
RUN rm ./Logger.moon
COPY ./src/Logger.moon .

WORKDIR /home/.aegisub/automation/ffi-experiments

RUN luarocks install moonscript

RUN meson setup build -Ddefault_library=static
RUN meson compile -C build

# build from the ffi in the aegiscripts

#WORKDIR /home/.aegisub/automation

WORKDIR /home/.aegisub/automation

RUN mkdir -p autoload include/l0 include/BM/BadMutex include/PT/PreciseTimer include/DM/DownloadManager


# Shapery
RUN cp /home/.aegisub/automation/ILL-Aegisub-Scripts/macros/*  autoload/
RUN ls /home/.aegisub/automation/ILL-Aegisub-Scripts/modules/ILL
RUN mv /home/.aegisub/automation/ILL-Aegisub-Scripts/modules/ILL include/
RUN mv /home/.aegisub/automation/ILL-Aegisub-Scripts/modules/clipper2 include/

#DependancyControl
RUN mv DependencyControl/modules/DependencyControl DependencyControl/modules/DependencyControl.moon include/l0/
RUN mv DependencyControl/macros/l0.DependencyControl.Toolbox.moon autoload/

# SubInspector
RUN mv /home/.aegisub/automation/SubInspector/examples/Aegisub/Inspector.moon /home/.aegisub/automation/include/SubInspector
RUN mv /home/.aegisub/automation/SubInspector/build/src/libSubInspector.so /home/.aegisub/automation/include/SubInspector/Inspector


# Anything else
RUN mv YUtils/src/Yutils.lua include/Yutils.lua
RUN mv ffi-experiments/build/requireffi include/
RUN mv ffi-experiments/build/bad-mutex/libBadMutex.so* include/BM/BadMutex/
RUN mv ffi-experiments/build/bad-mutex/BadMutex.lua include/BM/
RUN mv ffi-experiments/build/precise-timer/libPreciseTimer.so* include/PT/PreciseTimer/
RUN mv ffi-experiments/build/precise-timer/PreciseTimer.lua include/PT/
RUN mv ffi-experiments/build/download-manager/libDownloadManager.so* include/DM/DownloadManager/
RUN mv ffi-experiments/build/download-manager/DownloadManager.lua include/DM/


RUN rm -rf DependencyControl/ ffi-experiments/ YUtils/ ILL-Aegisub-Scripts/
#SubInspector/

RUN luarocks install luajson 1.3.3-1




# custom scripts
WORKDIR /home/.aegisub/automation/autoload
COPY ./scripts .

# move .aegisub to right location
RUN mv /home/.aegisub /root


# Install Aegisub-cli
WORKDIR /home
RUN git clone https://github.com/Myaamori/aegisub-cli
WORKDIR /home/aegisub-cli

RUN python3 -m pip install meson==0.62 # Downgrade Meson due to sandbox violation (known issue)

RUN meson --prefix=/usr --buildtype=release build
RUN meson compile -C build src/aegisub-cli

RUN mv build/src/aegisub-cli /usr/bin/
RUN mv build/src/libresrc/libresrc.a /usr/lib/
RUN mv build/src/libresrc/default_config.h /usr/include/

WORKDIR /home

COPY ./input.ass .

# Fix issue with dependancy logger -» use new user

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



RUN mkdir -p /root/.aegisub
RUN mkdir -p /root/.aegisub/log

WORKDIR /home

RUN mkdir -p /aegisub-tmp
RUN chmod 777 /aegisub-tmp
RUN export TMPDIR=/aegisub-tmp
RUN export TMP=/aegisub-tmp
RUN export TEMP=/aegisub-tmp

RUN useradd -m -s /bin/bash aegisub
RUN chown -R aegisub:aegisub /tmp

RUN mv /root/.aegisub /home/aegisub
RUN mkdir -p /home/aegisub/.aegisub/log
RUN mkdir -p /root/.aegisub/log
RUN mkdir -p /home/log
RUN mkdir -p /home/aegisub/log

RUN chown -R aegisub:aegisub /home/aegisub
RUN chown -R aegisub:aegisub /tmp
RUN chown -R aegisub:aegisub /aegisub-tmp

RUN chmod -R 755 /home/aegisub/.aegisub
RUN chmod -R 777 /home/aegisub/.aegisub/automation
RUN chown -R aegisub:aegisub /home/aegisub

USER aegisub

RUN find /home/aegisub/.aegisub -type d -exec ls -ld {} \;

RUN umask 022 && aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Update Script"
#RUN umask 022 && aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script"
# /Update All
#aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button": 0, "values": {"macro":"Shapery v2.6.1"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script"

