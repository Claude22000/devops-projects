FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# ---------------------------
# System dependencies
# ---------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    wget \
    git \
    zip \
    ca-certificates \
    gnupg \
    openjdk-17-jdk \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Android SDK setup
# ---------------------------
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools

WORKDIR /opt

# Updated Android command line tools
# (newer than 11076708 to reduce old vulnerable embedded jars)
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O cmdline-tools.zip \
    && unzip cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm -f cmdline-tools.zip

# Accept licenses
RUN yes | sdkmanager --licenses

# Install newer Android SDK packages
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-35" \
    "build-tools;35.0.0"

# ---------------------------
# Node.js + secure npm
# ---------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@11.6.4 \
    && npm cache clean --force \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Final workspace
# ---------------------------
WORKDIR /workspace

CMD ["bash"]