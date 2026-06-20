# ============================================================
# Dark Factory — Hermes Agent + Stack de coding agents
# ============================================================
# Extiende la imagen oficial de Hermes. Dokploy hace build
# desde este Dockerfile cada vez que haces deploy.
#
# Base: nousresearch/hermes-agent:latest
#   - Debian 13 (trixie)
#   - Python 3.13
#   - Node 22 LTS (+ npm, corepack)
#   - s6-overlay como PID 1
#   - Usuario runtime: hermes (UID 10000, no-root)
# ============================================================

FROM nousresearch/hermes-agent:latest

# ============================================================
# 1. System dependencies
# ============================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        gnupg \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# 2. Claude Code — coding agent de Anthropic
# ============================================================
RUN npm install -g @anthropic-ai/claude-code@latest

# ============================================================
# 3. Command Code (cmd) — coding agent via OpenRouter
# ============================================================
RUN npm install -g command-code@latest

# ============================================================
# 4. OpenCode — open source coding agent
# ============================================================
RUN curl -fsSL https://raw.githubusercontent.com/anomalyco/opencode/refs/heads/dev/install | bash

# ============================================================
# 5. pnpm — package manager (Next.js/NestJS projects)
# ============================================================
RUN npm install -g pnpm@latest

# ============================================================
# 6. GitHub CLI — clone, PRs, issues
# ============================================================
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
          https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
# 7. Engram — persistent memory for coding agents (MCP)
# ============================================================
# Single Go binary, SQLite+FTS5, MCP stdio server.
# Agents like Claude Code / OpenCode use it to remember
# project conventions across sessions.
ARG ENGRAM_VERSION=v1.17.0
RUN <<EOF
  curl -fsSL "https://github.com/Gentleman-Programming/engram/releases/download/${ENGRAM_VERSION}/engram_${ENGRAM_VERSION#v}_linux_amd64.tar.gz" \
      -o /tmp/engram.tar.gz
  tar -xzf /tmp/engram.tar.gz -C /tmp
  mv /tmp/engram /usr/local/bin/engram
  chmod +x /usr/local/bin/engram
  rm /tmp/engram.tar.gz
  engram version
EOF

# ============================================================
# 8. Workspace directory
# ============================================================
RUN mkdir -p /opt/workspaces && chown hermes:hermes /opt/workspaces

# ============================================================
# 9. Cleanup
# ============================================================
RUN npm cache clean --force

# Hereda automaticamente de la imagen base:
#   ENTRYPOINT ["/init", "/opt/hermes/docker/main-wrapper.sh"]
#   USER root (s6-overlay baja privilegios a hermes en runtime)
#   HERMES_HOME=/opt/data
#   PATH con /opt/data/.local/bin
