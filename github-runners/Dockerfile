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
# Node.js
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