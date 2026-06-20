FROM nousresearch/hermes-agent:latest

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code@latest

RUN npm install -g command-code@latest

RUN curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/dev/install | bash

RUN npm install -g pnpm@latest

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
          https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

ARG ENGRAM_VERSION=v1.17.0
RUN ENGRAM_VERSION=${ENGRAM_VERSION} && \
    VERSION_NO_V=$${ENGRAM_VERSION#v} && \
    curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/$${ENGRAM_VERSION}/engram_$${VERSION_NO_V}_linux_amd64.tar.gz" \
      -o /tmp/engram.tar.gz && \
    tar -xzf /tmp/engram.tar.gz -C /tmp && \
    mv /tmp/engram /usr/local/bin/engram && \
    chmod +x /usr/local/bin/engram && \
    rm /tmp/engram.tar.gz && \
    engram version

RUN mkdir -p /opt/workspaces && chown hermes:hermes /opt/workspaces

RUN npm cache clean --force
