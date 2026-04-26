FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------
# Basic dependencies
# ---------------------------
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    wget \
    git \
    zip \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------
# Android SDK setup
# ---------------------------
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools

WORKDIR /opt

# Download Android command line tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O cmdline-tools.zip \
    && unzip cmdline-tools.zip -d $ANDROID_SDK_ROOT/cmdline-tools \
    && mv $ANDROID_SDK_ROOT/cmdline-tools/cmdline-tools $ANDROID_SDK_ROOT/cmdline-tools/latest \
    && rm cmdline-tools.zip

# Accept licenses + install packages
RUN yes | sdkmanager --licenses

RUN sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"

# ---------------------------
# Node.js (optional for RN / Expo)
# ---------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# ---------------------------
# Set working directory
# ---------------------------
WORKDIR /workspace

CMD ["bash"]