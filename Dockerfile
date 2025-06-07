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
WORKDIR /usr/src

RUN git clone https://github.com/arch1t3cht/Aegisub.git -b feature_12
#RUN ls -la
WORKDIR /usr/src/Aegisub
#RUN ls -la
RUN meson setup build --prefix=/usr --buildtype=release
RUN meson compile -C build
WORKDIR /usr/src/Aegisub/build
RUN ninja install

# Set up `Automation 4` modules for Aegisub
RUN mkdir -p /usr/src/.aegisub/automation
WORKDIR /usr/src/.aegisub/automation

RUN git clone https://github.com/TypesettingTools/DependencyControl.git
RUN git clone https://github.com/TypesettingTools/YUtils.git
RUN git clone https://github.com/arch1t3cht/ffi-experiments.git

WORKDIR /usr/src/.aegisub/automation/DependencyControl
RUN git checkout v0.6.3-alpha

WORKDIR /usr/src/.aegisub/automation/ffi-experiments

RUN luarocks install moonscript

RUN meson setup build -Ddefault_library=static
RUN meson compile -C build
WORKDIR /usr/src/.aegisub/automation
#cd ..

RUN mkdir -p autoload include/l0 include/BM/BadMutex include/PT/PreciseTimer include/DM/DownloadManager

RUN ls -la

RUN cp /usr/src/.aegisub/automation/DependencyControl/macros/l0.DependencyControl.Toolbox.moon /usr/src/Aegisub/automation/autoload/

RUN mv DependencyControl/modules/DependencyControl DependencyControl/modules/DependencyControl.moon include/l0/
RUN mv DependencyControl/macros/l0.DependencyControl.Toolbox.moon autoload/
RUN mv YUtils/src/Yutils.lua include/Yutils.lua
RUN mv ffi-experiments/build/requireffi include/
RUN mv ffi-experiments/build/bad-mutex/libBadMutex.so* include/BM/BadMutex/
RUN mv ffi-experiments/build/bad-mutex/BadMutex.lua include/BM/
RUN mv ffi-experiments/build/precise-timer/libPreciseTimer.so* include/PT/PreciseTimer/
RUN mv ffi-experiments/build/precise-timer/PreciseTimer.lua include/PT/
RUN mv ffi-experiments/build/download-manager/libDownloadManager.so* include/DM/DownloadManager/
RUN mv ffi-experiments/build/download-manager/DownloadManager.lua include/DM/


RUN rm -rf DependencyControl/ ffi-experiments/ YUtils/

RUN luarocks install luajson

#WORKDIR /usr/src/Aegisub/automation/autoload/





# custom scripts
WORKDIR /usr/src/.aegisub/automation/autoload
COPY ./scripts .


# Install Aegisub-cli
WORKDIR /usr/src
RUN git clone https://github.com/Myaamori/aegisub-cli
WORKDIR /usr/src/aegisub-cli

RUN python3 -m pip install meson==0.62 # Downgrade Meson due to sandbox violation (known issue)

RUN meson --prefix=/usr --buildtype=release build
RUN meson compile -C build src/aegisub-cli

RUN mv build/src/aegisub-cli /usr/bin/
RUN mv build/src/libresrc/libresrc.a /usr/lib/
RUN mv build/src/libresrc/default_config.h /usr/include/

