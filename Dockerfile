FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
WORKDIR /build

# Install all dependencies needed for build + runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-setuptools git curl ca-certificates \
    cmake pkg-config ninja-build build-essential \
    libx11-dev libwxgtk3.0-gtk3-dev libfreetype6-dev libfontconfig1-dev \
    libass-dev libasound2-dev libffms2-dev intltool \
    libhunspell-dev libuchardet-dev libpulse-dev \
    libopenal-dev libxxhash-dev nasm  \
    libcurl4-gnutls-dev \
    libboost-all-dev libreadline-dev \
    fonts-liberation fonts-dejavu fontconfig \
    cabextract \
    && python3 -m pip install --upgrade pip meson \
    && rm -rf /var/lib/apt/lists/*

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

WORKDIR /home
# ---- Install additional fonts ----
COPY ./src/webfonts.tar.gz ./webfonts.tar.gz
RUN tar -xzf webfonts.tar.gz \
    && cd msfonts/ \
    && cabextract *.exe \
    && mkdir -p ~/.local/share/fonts/ \
    && cp *.ttf *.TTF ~/.local/share/fonts/



# Runtime stage
FROM ubuntu:22.04 AS runtime
ENV DEBIAN_FRONTEND=noninteractive

# ---- COPY Files ----
COPY --from=builder /usr/local/bin/aegisub-cli /usr/local/bin/
COPY --from=builder /root/.local/share/fonts/* /root/.local/share/fonts/


# ---- Install packages ----
RUN apt-get update  \
    && apt-get install -y --no-install-recommends \
    libwxgtk3.0-gtk3-0v5 libwxbase3.0-0v5 \
    libuchardet0 libx11-6 fontconfig libass9 \
    curl ca-certificates \
    libboost-program-options1.74.0 \
    libfreetype6-dev libfontconfig1-dev \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    && ldconfig


# ---- Setup Aegisub automation ----
ARG HOME='/root'
RUN mkdir -p ${HOME}/.aegisub/config/ \
    && mkdir -p ${HOME}/.aegisub/log \
    && mkdir -p ${HOME}/.aegisub/automation/autoload \
    && mkdir -p ${HOME}/.aegisub/automation/include


# ---- Build Dependency Control ----
WORKDIR /home/build
COPY ../src/Logger.moon ./Logger.moon
RUN curl -L https://github.com/RellikJaeger/DependencyControl/releases/download/v0.6.4-alpha/DependencyControl-v0.6.4-Linux-amd64.tar.gz -o DependencyControl-v0.6.4-Linux-amd64.tar.gz \
    && tar -xvf ./DependencyControl-v0.6.4-Linux-amd64.tar.gz \
    && rm -f DependencyControl-v0.6.4-Linux-amd64/include/l0/DependencyControl/Logger.moon \
    && cp Logger.moon DependencyControl-v0.6.4-Linux-amd64/include/l0/DependencyControl/ \
    && mv ./DependencyControl-v0.6.4-Linux-amd64/include/* ${HOME}/.aegisub/automation/include/ \
    && mv ./DependencyControl-v0.6.4-Linux-amd64/autoload/* ${HOME}/.aegisub/automation/autoload/ \
    && rm -rf DependencyControl-v0.6.4-Linux-amd64

# ---- Automation scripts ----
WORKDIR ${HOME}/.aegisub/automation
#COPY ../scripts ./scripts/

# ---- Copy Input Script ----
WORKDIR /home
COPY ../input.ass .
RUN rm -rf /home/build

WORKDIR /home
# ---- Install aegisub ----
RUN apt-get update \
  && apt-get install -y --no-install-recommends software-properties-common gpg-agent \
  && add-apt-repository ppa:alex-p/aegisub \
  && apt-get update \
  && apt-get install -y --no-install-recommends aegisub \
  && apt-get purge -y software-properties-common gpg-agent \
  && apt-get autoremove -y \
  && rm -rf /var/lib/apt/lists/*

# Test run
RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button":0,"values":{"macro":"DependencyControl"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script" || true
RUN aegisub-cli --automation l0.DependencyControl.Toolbox.moon --dialog '{"button": 0, "values": {"macro":"Shapery v2.6.1"}}' --loglevel 4 input.ass dummy_out.ass "DependencyControl/Install Script" || true
#RUN aegisub-cli --automation ILL.Shapery.moon --loglevel 4 input.ass dummy_out.ass ": Shapery macros :/Shape expand" || true
