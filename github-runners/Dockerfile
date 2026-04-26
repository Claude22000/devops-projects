FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------
# Basic dependencies
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
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools

WORKDIR /opt

# ---------------------------
# Download latest Android command line tools
#
# NOTE:
# Replace the version below if Google releases a newer one.
# This is newer than 11076708 and helps reduce old vulnerable jars.
# ---------------------------
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip -O cmdline-tools.zip \
    && unzip cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm -f cmdline-tools.zip

# ---------------------------
# Accept licenses
# ---------------------------
RUN yes | sdkmanager --licenses

# ---------------------------
# Install Android SDK packages
#
# If build-tools 35.x is available in your environment,
# prefer that over 34.0.0
# ---------------------------
RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;35.0.0"

# ---------------------------
# Node.js + secure npm update
# ---------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm cache clean --force \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Final workspace
# ---------------------------
WORKDIR /workspace

CMD ["bash"]