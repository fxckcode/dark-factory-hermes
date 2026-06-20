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

# Engram v1.17.0 — single Go binary, no deps
# Actualizar version: cambiar los dos numeros abajo (tag y filename)
RUN curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/v1.17.0/engram_1.17.0_linux_amd64.tar.gz" \
      -o /tmp/engram.tar.gz && \
    tar -xzf /tmp/engram.tar.gz -C /tmp && \
    mv /tmp/engram /usr/local/bin/engram && \
    chmod +x /usr/local/bin/engram && \
    rm /tmp/engram.tar.gz && \
    engram version

RUN mkdir -p /opt/workspaces && chown hermes:hermes /opt/workspaces

RUN npm cache clean --force
